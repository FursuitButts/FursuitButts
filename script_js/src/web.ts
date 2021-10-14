import WebSocket from "ws";
import express from "express";
import morgan from "morgan";
import E621, { Post } from "e621";
import fetch from "node-fetch";
import http from "http";
import * as fs from "fs";
const e6 = new E621();
process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";
if (!process.env.API_TOKEN) throw new Error("No api token provided.");
const app = express();
const file = `${__dirname}/../posts`;
app.use(morgan("dev")).use("/", async(req, res) => res.sendFile(`${__dirname}/web.html`));
const server = http.createServer(app);
const ws = new WebSocket.Server({ server });
let current: Post | null = null;
function get() { return fs.readFileSync(file).toString().split("\n").filter(Boolean).map(Number); }
function set(c: Array<string | number>) { fs.writeFileSync(file, c.join("\n")); }
ws
	.on("connection", async(sock) => {
		sock
			.on("open", () => console.log("WS Client Open"))
			.on("close", () => console.log("WS Client Close"))
			.on("message", async(d) => {
				const { tags, rating } = JSON.parse(d.toString()) as { tags: Array<string>; rating: "s" | "q" | "e"; };
				const { post_id: newId } = await fetch("https://yiff.rest/uploads.json", {
					method: "POST",
					headers: {
						"Authorization": Buffer.from(`Donovan_DMC:${process.env.API_TOKEN!}`).toString("base64"),
						"Content-Type": "application/x-www-form-urlencoded"
					},
					body: `upload[tag_string]=${encodeURIComponent(tags.join(" "))}&upload[rating]=${rating}&upload[direct_url]=${encodeURIComponent(current!.file.url)}&upload[source]=${encodeURIComponent([`https://e621.net/posts/${current!.id}`, ...current!.sources].join("\n"))}&upload[locked_rating]=true`
				}).then(async(r) => {
					if (r.status >= 300) throw new Error(`Upload Error: ${r.status} ${r.statusText} "${await r.text()}"`);
					else return r.json() as Promise<{ success: boolean; reason?: string; location: string; post_id: number; }>;
				});
				set(get().slice(1));
				current = await e6.getPostById(get()[0]);
				sock.send(JSON.stringify([current.id, current.file.url, newId, get().length]));
			});

		if (current === null) current = await e6.getPostById(get()[0]);
		sock.send(JSON.stringify([current.id, current.file.url, null, get().length]));
	})
	.on("close", () => console.log("WS Server Close"));
server.listen(80, "import.local", () => console.log("Listening on http://import.local and ws://import.local"));
