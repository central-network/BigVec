import self from "./Window.mjs";

let w, b, s, o, v, a, r;
const logs = [];

b = new self.ArrayBuffer(24);
s = new self.String('h.js');
o = new self.Object();
v = new self.Number(2);
a = new self.Array();

o.name = v;
a[0] = b;
w = new self.Worker(s, o);
r = w.postMessage(a);


logs.push(b, s, o, v, a, w, r);

setTimeout(() => console.log(logs), 500)
