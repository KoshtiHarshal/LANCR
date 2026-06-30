# LANCR — Play production-access application (draft answers)

> Personal account closed-testing → production access form. Fill every `[bracket]`
> with REAL details from your 14-day closed test before submitting. Keep it honest
> and specific — Google rejects generic / fabricated applications.

## Q1 — What does your app do, and who is it for?
LANCR is a mobile-first freelance marketplace for Android that connects clients with
freelancers. Clients post projects (with categories and budgets), browse and save
projects, receive proposals, chat with freelancers in real time, and review and hire
them. Freelancers browse open projects, send proposals, message clients, and build a
profile. It's aimed at small businesses, solo entrepreneurs, and independent
freelancers who want a lightweight way to hire and find work from their phone.

## Q2 — How did you run your closed test (recruiting and communicating with testers)?
I recruited [12] testers from my personal and professional network — [friends, former
colleagues, and people who actually hire or do freelance work] so the feedback came
from real target users. I shared the Play closed-testing opt-in link directly and gave
each tester a short guide on what to try: register, post a project, browse and filter,
save a project, send a proposal, chat, and leave a review. I kept in contact over
[WhatsApp / email / a group chat] and asked for feedback throughout the 14-day test.

## Q3 — What feedback did testers give? (give concrete examples)
[REPLACE with 2–3 specific things testers actually said. Examples to adapt:]
- [The project-posting flow was clear, but one tester wanted search inside the category picker.]
- [Push notifications arrived reliably and made the chat feel responsive.]
- [A tester asked for a way to filter their saved projects.]

## Q4 — What changes did you make based on that feedback?
[REPLACE with the real changes you shipped or queued. Examples to adapt:]
- [Added category filtering on the Browse screen.]
- [Fixed a theme-switch rendering glitch reported on dark mode.]
- [Tweaked the copy on the proposal screen for clarity.]

## Q5 — Why is your app ready for production?
The core flows — register, post a project, browse/filter, save, send proposals,
real-time chat, reviews, and push notifications — were tested end-to-end on real
devices and are stable. I verified push delivery on the production (Play-signed) build,
wired Firebase Crashlytics for live crash monitoring, and completed the privacy policy,
in-app account-deletion flow, Data Safety form, and content rating. After 12 testers
ran the app for 14 days with no blocking issues and I addressed their feedback, I'm
confident it's ready for a staged production rollout.

---
### If the form also asks shorter prompts
- **Number of testers:** [12]
- **Test countries:** [India / your selected regions]
- **Core value:** Hire freelancers and find freelance work from your phone — post,
  propose, chat, review, hire.
- **Target audience:** Adults (18+) who hire or do freelance/contract work.
