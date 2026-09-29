// Generates the SAMPLE (not real) scheme, air code sheet, DMSL and blank
// templates in assets/samples/ as both .csv and .xlsx.
//
//   dart run tool/make_samples.dart
import 'dart:io';

import 'package:sorting_sahayak/data/import/table_reader.dart';

const schemeHeader = ['Type', 'PIN', 'PIN From', 'PIN To', 'Prefix', 'Office', 'District', 'State', 'Bag No', 'Bag Name', 'Section', 'Remarks', 'Category', 'Connectivity', 'Colour'];
const airHeader = ['Type', 'PIN', 'PIN From', 'PIN To', 'Prefix', 'District', 'State', 'Air Code', 'Station', 'Via', 'Remarks'];
const dmslHeader = ['Type', 'PIN', 'PIN From', 'PIN To', 'Prefix', 'Office', 'District', 'State', 'L2 Hub', 'L1 Hub', 'Direct closure (Y/N)', 'Connectivity', 'Remarks'];

List<String> s(String type, {String pin = '', String from = '', String to = '', String prefix = '', String office = '', String district = '', String state = '', required String bag, String name = '', String section = '', String remarks = '', String category = '', String conn = '', String colour = ''}) =>
    [type, pin, from, to, prefix, office, district, state, bag, name, section, remarks, category, conn, colour];

final schemeRows = [
  ['SAMPLE – not real. Demo sorting scheme for practice only – replace with your office scheme.'],
  schemeHeader,
  s('PIN', pin: '574201', bag: 'Bag 12', name: 'Puttur SO', section: 'A', colour: '#D32F2F'),
  s('PIN', pin: '574202', bag: 'Bag 12', name: 'Puttur SO', section: 'A'),
  s('PIN', pin: '574239', bag: 'Bag 14', name: 'Sullia SO', section: 'A', colour: '#2E7D32'),
  s('PIN', pin: '574241', bag: 'Bag 13', name: 'Uppinangady SO', section: 'A', colour: '#1565C0'),
  s('PIN', pin: '575001', bag: 'Bag 01', name: 'Mangaluru HO', section: 'B', colour: '#6A1B9A'),
  s('PIN', pin: '576101', bag: 'Bag 21', name: 'Udupi HO', section: 'C', colour: '#EF6C00'),
  s('PIN', pin: '576104', bag: 'Bag 22', name: 'Manipal SO', section: 'C', colour: '#00796B'),
  s('PIN', pin: '574104', bag: 'Bag 23', name: 'Karkala SO', section: 'C', colour: '#6D4C41'),
  s('PIN', pin: '560001', bag: 'SP-BLR', name: 'Speed Post Bengaluru', category: 'Speed Post', conn: 'Air', colour: '#F9A825'),
  s('Range', from: '574201', to: '574299', bag: 'Bag 12', name: 'Puttur SO', remarks: 'Puttur group'),
  s('Range', from: '574210', to: '574219', bag: 'Bag 15', name: 'Bantwal / Belthangady', section: 'A', colour: '#D81B60'),
  s('Range', from: '575001', to: '575030', bag: 'Bag 01', name: 'Mangaluru HO', remarks: 'City delivery'),
  s('Range', from: '576101', to: '576125', bag: 'Bag 21', name: 'Udupi HO'),
  s('Range', from: '576201', to: '576299', bag: 'Bag 24', name: 'Kundapura SO', section: 'C', colour: '#455A64'),
  s('Prefix', prefix: '574', bag: 'Bag 10', name: 'Puttur Division (other)', section: 'A', colour: '#880E4F'),
  s('Prefix', prefix: '575', bag: 'Bag 02', name: 'Mangaluru NSH', section: 'B', colour: '#0097A7'),
  s('Prefix', prefix: '576', bag: 'Bag 20', name: 'Udupi Division', section: 'C', colour: '#EF6C00'),
  s('Prefix', prefix: '57', bag: 'Bag 30', name: 'Karnataka – other', section: 'D', colour: '#616161'),
  s('Prefix', prefix: '56', bag: 'Bag 40', name: 'Bengaluru NSH', section: 'D', colour: '#1565C0'),
  s('Prefix', prefix: '5', bag: 'Bag 50', name: 'Southern states', section: 'E', colour: '#2E7D32'),
  s('Prefix', prefix: '671', bag: 'Bag 60', name: 'Kasaragod (Kerala)', section: 'E', colour: '#00796B'),
  s('Office', office: 'Puttur', bag: 'Bag 12', name: 'Puttur SO', remarks: 'Articles without PIN'),
  s('Office', office: 'Sullia', bag: 'Bag 14', name: 'Sullia SO'),
  s('Office', office: 'Manipal', bag: 'Bag 22', name: 'Manipal SO'),
  s('Office', office: 'Kasaragod', bag: 'Bag 60', name: 'Kasaragod (Kerala)'),
  s('District', district: 'Dakshina Kannada', bag: 'Bag 10', name: 'Puttur Division (other)'),
  s('District', district: 'Udupi', bag: 'Bag 20', name: 'Udupi Division'),
  s('District', district: 'Hassan', bag: 'Bag 31', name: 'Hassan HO', colour: '#6D4C41'),
  s('State', state: 'Kerala', bag: 'Bag 61', name: 'Kerala – other', colour: '#0097A7'),
  s('Prefix', prefix: '574', bag: 'P-01', name: 'Parcel – Puttur Division', category: 'Parcel (surface)', conn: 'Surface', colour: '#795548'),
  s('Prefix', prefix: '56', bag: 'AP-01', name: 'Air parcel – Bengaluru', category: 'Air Parcel', conn: 'Air', colour: '#FBC02D'),
  s('Prefix', prefix: '60', bag: 'AP-02', name: 'Air parcel – Chennai', category: 'Air Parcel', conn: 'Air', colour: '#FFA000'),
  s('Default', bag: 'Bag 99', name: 'All other – send to TMO', section: 'Z', remarks: 'Out of circle', colour: '#212121'),
];

List<String> a(String type, {String pin = '', String from = '', String to = '', String prefix = '', String district = '', String state = '', required String code, String station = '', String via = '', String remarks = 'SAMPLE – not real'}) =>
    [type, pin, from, to, prefix, district, state, code, station, via, remarks];

final airRows = [
  ['SAMPLE – not real. Demo air code sheet – your office decides the real codes.'],
  airHeader,
  a('PIN', pin: '110001', code: 'DEL', station: 'Delhi (demo)'),
  a('Range', from: '700001', to: '700099', code: 'CCU', station: 'Kolkata (demo)'),
  a('Prefix', prefix: '56', code: 'BLR', station: 'Bengaluru (demo)'),
  a('Prefix', prefix: '575', code: 'IXE', station: 'Mangaluru (demo)', via: 'Mangaluru hub (demo)'),
  a('Prefix', prefix: '60', code: 'MAA', station: 'Chennai (demo)'),
  a('Prefix', prefix: '11', code: 'DEL', station: 'Delhi (demo)'),
  a('Prefix', prefix: '40', code: 'BOM', station: 'Mumbai (demo)'),
  a('Prefix', prefix: '50', code: 'HYD', station: 'Hyderabad (demo)'),
  a('Prefix', prefix: '68', code: 'COK', station: 'Kochi (demo)'),
  a('District', district: 'Mysuru', code: 'MYQ', station: 'Mysuru (demo)', via: 'Bengaluru (demo)'),
  a('State', state: 'Kerala', code: 'TRV', station: 'Thiruvananthapuram (demo)'),
  a('Prefix', prefix: '79', code: 'ZZQ', station: 'Unknown code demo', remarks: 'SAMPLE – not real; shows the unknown-code warning'),
];

List<String> d(String type, {String pin = '', String from = '', String to = '', String prefix = '', String office = '', String district = '', String state = '', String l2 = '', required String l1, String direct = 'N', String conn = '', String remarks = 'SAMPLE – not real'}) =>
    [type, pin, from, to, prefix, office, district, state, l2, l1, direct, conn, remarks];

final dmslRows = [
  ['SAMPLE – not real. Demo DMSL, version SAMPLE-2026-10, valid from 2026-10-07.'],
  dmslHeader,
  d('PIN', pin: '574201', l2: 'Puttur L2 (demo)', l1: 'Mangaluru L1 (demo)', conn: 'Surface'),
  d('PIN', pin: '574239', l1: 'Mangaluru L1 (demo)', direct: 'Y', conn: 'Surface', remarks: 'SAMPLE – not real; direct closure'),
  d('Prefix', prefix: '574', l2: 'Puttur L2 (demo)', l1: 'Mangaluru L1 (demo)', conn: 'Surface'),
  d('Prefix', prefix: '575', l2: 'Mangaluru L2 (demo)', l1: 'Mangaluru L1 (demo)', conn: 'Surface'),
  d('Prefix', prefix: '576', l2: 'Udupi L2 (demo)', l1: 'Mangaluru L1 (demo)', conn: 'Surface'),
  d('Prefix', prefix: '56', l1: 'Bengaluru L1 (demo)', direct: 'Y', conn: 'Air'),
  d('Prefix', prefix: '60', l1: 'Chennai L1 (demo)', direct: 'Y', conn: 'Air'),
  d('Prefix', prefix: '11', l1: 'Delhi L1 (demo)', direct: 'Y', conn: 'Air'),
  d('Range', from: '671100', to: '671599', l2: 'Kasaragod L2 (demo)', l1: 'Kannur L1 (demo)', conn: 'Surface', remarks: 'SAMPLE – not real; other circle'),
  d('Office', office: 'Sullia', l1: 'Mangaluru L1 (demo)', direct: 'Y', conn: 'Surface'),
  d('District', district: 'Hassan', l2: 'Hassan L2 (demo)', l1: 'Mysuru L1 (demo)', conn: 'Surface'),
  d('Default', l1: 'Mangaluru L1 (demo)', remarks: 'SAMPLE – not real; connectivity left blank on purpose'),
];

final templates = {
  'template_scheme': [
    schemeHeader,
    s('PIN', pin: '574201', bag: 'Bag 12', name: 'Puttur SO', section: 'A', remarks: 'example row – delete', colour: '#D32F2F'),
    s('Range', from: '574201', to: '574299', bag: 'Bag 12', remarks: 'example row – delete'),
    s('Prefix', prefix: '575', bag: 'Bag 02', name: 'Mangaluru NSH', remarks: 'example row – delete'),
    s('Default', bag: 'Bag 99', name: 'All other', remarks: 'example row – delete'),
  ],
  'template_air_codes': [
    airHeader,
    a('Prefix', prefix: '56', code: 'ABC', station: 'Station name', remarks: 'example row – delete'),
  ],
  'template_dmsl': [
    dmslHeader,
    d('Prefix', prefix: '574', l2: 'L2 hub name', l1: 'L1 hub name', conn: 'Surface', remarks: 'example row – delete'),
  ],
};

void main() {
  final dir = Directory('assets/samples')..createSync(recursive: true);
  void write(String name, List<List<String>> rows) {
    final width = rows.map((r) => r.length).reduce((a, b) => a > b ? a : b);
    final padded = [for (final r in rows) [...r, ...List.filled(width - r.length, '')]];
    File('${dir.path}/$name.csv').writeAsStringSync(writeCsv(padded));
    File('${dir.path}/$name.xlsx').writeAsBytesSync(writeXlsx({name.startsWith('sample') ? 'SAMPLE' : 'Template': padded}));
    stdout.writeln('wrote $name (${rows.length} rows)');
  }

  write('sample_scheme', schemeRows);
  write('sample_air_codes', airRows);
  write('sample_dmsl', dmslRows);
  templates.forEach(write);
}
