import config from "../config.json";
import E621 from "e621";
const y = new E621({
  authUser: config.user,
  authKey: config.key,
  instanceHost: "yiff.rest",
  instanceSSL: true
});

if(process.argv.length < 5) throw new Error("Usage: <user> <type> <body>");
const user = process.argv[3].toLowerCase();
const v = process.argv[2].toLowerCase();
const type = v === "positive" ? "positive" : v === "negative" ? "negative" : "neutral";
void y.userFeedback.create({
  username: user,
  category: type,
  body: process.argv.slice(3).join(" ")
}).then(r => {
  console.log("Record Created For \"%s\", https://yiff.rest/user_feedbacks/%d", user, r.id);
})
