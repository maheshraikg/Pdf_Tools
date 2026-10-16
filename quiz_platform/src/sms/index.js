// SMS gateway abstraction. Providers:
//   console : development only — logs the message (never allowed in production)
//   twilio  : Twilio Programmable Messaging
//   msg91   : MSG91 (DLT-compliant Indian SMS gateway; uses approved templates)
// Credentials come exclusively from environment variables (see config.js).

class ConsoleProvider {
  constructor(log) {
    this.log = log;
    this.outbox = []; // inspected by automated tests
  }
  async sendOtp(phone, code) {
    this.outbox.push({ phone, code, kind: 'otp', at: Date.now() });
    if (this.outbox.length > 1000) this.outbox.shift();
    this.log?.info({ phone: `…${phone.slice(-4)}`, code }, '[DEV SMS] OTP');
  }
  async sendText(phone, text) {
    this.outbox.push({ phone, text, kind: 'text', at: Date.now() });
    if (this.outbox.length > 1000) this.outbox.shift();
    this.log?.info({ phone: `…${phone.slice(-4)}`, text }, '[DEV SMS] text');
  }
  lastOtpFor(phone) {
    for (let i = this.outbox.length - 1; i >= 0; i--) {
      if (this.outbox[i].phone === phone && this.outbox[i].kind === 'otp') return this.outbox[i].code;
    }
    return undefined;
  }
}

async function postWithTimeout(url, init, timeoutMs = 8000) {
  const ctrl = new AbortController();
  const t = setTimeout(() => ctrl.abort(), timeoutMs);
  try {
    const res = await fetch(url, { ...init, signal: ctrl.signal });
    if (!res.ok) {
      const body = await res.text().catch(() => '');
      throw new Error(`SMS provider HTTP ${res.status}: ${body.slice(0, 200)}`);
    }
    return res;
  } finally {
    clearTimeout(t);
  }
}

class TwilioProvider {
  constructor(cfg) {
    const { accountSid, authToken } = cfg.sms.twilio;
    if (!accountSid || !authToken || !(cfg.sms.twilio.from || cfg.sms.twilio.messagingServiceSid)) {
      throw new Error('Twilio requires TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN and TWILIO_FROM or TWILIO_MESSAGING_SERVICE_SID');
    }
    this.cfg = cfg.sms.twilio;
  }
  async sendText(phone, text) {
    const body = new URLSearchParams({ To: `+${phone}`, Body: text });
    if (this.cfg.messagingServiceSid) body.set('MessagingServiceSid', this.cfg.messagingServiceSid);
    else body.set('From', this.cfg.from);
    await postWithTimeout(`https://api.twilio.com/2010-04-01/Accounts/${this.cfg.accountSid}/Messages.json`, {
      method: 'POST',
      headers: {
        Authorization: `Basic ${Buffer.from(`${this.cfg.accountSid}:${this.cfg.authToken}`).toString('base64')}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body,
    });
  }
  async sendOtp(phone, code) {
    await this.sendText(phone, `${code} is your Quiz Competition verification code. It expires in 5 minutes. Do not share it with anyone.`);
  }
}

class Msg91Provider {
  constructor(cfg) {
    if (!cfg.sms.msg91.authKey || !cfg.sms.msg91.otpTemplateId) {
      throw new Error('MSG91 requires MSG91_AUTH_KEY and MSG91_OTP_TEMPLATE_ID');
    }
    this.cfg = cfg.sms.msg91;
  }
  async flow(templateId, phone, vars) {
    await postWithTimeout('https://control.msg91.com/api/v5/flow/', {
      method: 'POST',
      headers: { authkey: this.cfg.authKey, 'Content-Type': 'application/json' },
      body: JSON.stringify({ template_id: templateId, short_url: '0', recipients: [{ mobiles: phone, ...vars }] }),
    });
  }
  async sendOtp(phone, code) {
    // We generate and verify the OTP ourselves; MSG91 only delivers it.
    await this.flow(this.cfg.otpTemplateId, phone, { otp: code });
  }
  async sendText(phone, text) {
    if (!this.cfg.notifyTemplateId) throw new Error('MSG91_NOTIFY_TEMPLATE_ID not configured');
    await this.flow(this.cfg.notifyTemplateId, phone, { message: text.slice(0, 160) });
  }
}

export function createSmsProvider(cfg, log) {
  switch (cfg.sms.provider) {
    case 'console':
      if (cfg.isProd) throw new Error('console SMS provider is not allowed in production');
      return new ConsoleProvider(log);
    case 'twilio':
      return new TwilioProvider(cfg);
    case 'msg91':
      return new Msg91Provider(cfg);
    default:
      throw new Error(`Unknown SMS_PROVIDER "${cfg.sms.provider}"`);
  }
}
