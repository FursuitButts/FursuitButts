import * as fs from "fs"
import readline from "readline";
const jsonFile = `${__dirname}/../bur.json`;
const textFile = `${__dirname}/../bur.txt`;

if(!fs.existsSync(jsonFile)) fs.writeFileSync(jsonFile, "[]");
const old = JSON.parse(fs.readFileSync(jsonFile).toString()) as Array<["imply" | "alias", string, string]>;

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

process.nextTick(async() => {
  let n: string;
  if(process.argv.slice(2).length >= 3) n = process.argv.slice(2, 5).join(" ");
  else n = await new Promise<string>((resolve) => rl.question("What's the new BUR entry? (i/a tag_from tag_to)\n> ", resolve));
  const [t, from, to] = n.split(" ");
  const type = t === "i" ? "imply" as const : t === "a" ? "alias" as const : null;
  if(type === null) throw new Error("Invalid Type");
  const dup = old.find(([a, b, c]) => a === type && b === from && c === to);
  if(dup) {
    console.error("Duplicate.");
    process.exit(0);
  }
  old.push([type, from, to]);
  fs.writeFileSync(jsonFile, JSON.stringify(old));
  fs.writeFileSync(textFile, old.map(([a, b, c]) => `${a} ${b} -> ${c}`).join("\n"));
  console.log("Added.");
  process.exit(0);
});
