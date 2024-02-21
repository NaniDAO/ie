export const siteConfig = {
  name: "NANI Intents Engine",
  description: "Onchain Intentions",
  baseUrl:
    process.env.NODE_ENV === "development"
      ? "http://localhost:3000"
      : "https://ie.nani.ooo",
  githubUrl: "https://github.com/NaniDAO/ie",
  twitterId: "1643190364600422402",
  author: "Nani DAO",
  keywords: ["nani", "intents", "ai", "ethereum", "sepolia"],
};
