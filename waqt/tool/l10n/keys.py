import re,json,sys
s=open(sys.argv[1]).read()
def parse_literals(s,i):
    """parse adjacent dart string literals starting at i (skipping ws); return (value,end)"""
    out='';n=0
    while True:
        while s[i] in ' \n\t': i+=1
        if s[i] not in "'\"": break
        q=s[i]; i+=1; buf=''
        while s[i]!=q:
            if s[i]=='\\': buf+=s[i+1]; i+=2; continue
            buf+=s[i]; i+=1
        i+=1; out+=buf; n+=1
    return (out if n else None), i
keys=[]
for m in re.finditer(r'\b_(t|f)\(', s):
    v,_=parse_literals(s,m.end())
    if v is None: print('NOPARSE',s[m.start():m.start()+60],file=sys.stderr); continue
    if v not in keys: keys.append(v)
json.dump(keys,open(sys.argv[2],'w'),ensure_ascii=False,indent=0)
print(len(keys))
