import fetch from "node-fetch";
import E621 from "e621";
import readline from "readline";
process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";
if (!process.env.API_TOKEN) throw new Error("No api token provided.");
const e6 = new E621();
const id = Number(process.argv[2]);
if (isNaN(id)) throw new Error("Invalid post id provided.");

const rl = readline.createInterface({
	input: process.stdin,
	output: process.stdout
});
process.nextTick(async() => {
	const post = await e6.getPostById(id);
	console.log("Importing Post #%d - File URL: %s", post.id, post.file.url);
	const tags = await new Promise<string>((resolve) => rl.question("What tags should be used for this post?\n> ", resolve));
	const rating = await new Promise<string>((resolve) => rl.question("What should the rating of this post be?\n> ", resolve));
	const { post_id: newId } = await fetch("https://yiff.rest/uploads.json", {
		method: "POST",
		headers: {
			"Authorization": Buffer.from(`admin:${process.env.API_TOKEN!}`).toString("base64"),
			"Content-Type": "application/x-www-form-urlencoded"
		},
		body: `upload[tag_string]=${encodeURIComponent(tags)}&upload[rating]=${rating}&upload[direct_url]=${encodeURIComponent(post.file.url)}&upload[source]=${encodeURIComponent([`https://e621.net/posts/${post.id}`, ...post.sources].join("\n"))}&upload[locked_rating]=true`
	}).then(async(r) => {
		if (r.status >= 300) throw new Error(`Upload Error: ${r.status} ${r.statusText} "${await r.text()}"`);
		else return r.json() as Promise<{ success: boolean; reason?: string; location: string; post_id: number; }>;
	});
	console.log("Post Imported - ID: #%d - Link: https://yiff.rest/posts/%d", newId, newId);
	process.exit(0);
});
