const fs = require('fs');
const path = 'd:/hvac-master/apps/admin/src/app/(dashboard)/editor/page.tsx';
let s = fs.readFileSync(path, 'utf8');
const before = s;
s = s.replace(/\blanguages\b/g, 'editorLanguages');
fs.writeFileSync(path, s, 'utf8');
const count = (before.match(/\blanguages\b/g) || []).length;
console.log('replaced', count, 'occurrences');
