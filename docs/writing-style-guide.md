# Writing Style Guide: AI Tells and Ryan's Voice

**Date:** 2026-04-08
**Purpose:** Reference for co-writing. When RYAI drafts something that should sound like Ryan, use this. When editing AI-generated text to sound human, use this.

---

## Part 1: How AI Writes (The Tells)

These are patterns that flag text as AI-generated. Some are fine in casual AI-to-human conversation. All of them should be scrubbed when the goal is prose that sounds like a human wrote it.

### Punctuation and structure

The **em dash** is the biggest tell. AI uses them constantly, often where a comma or period would be more natural. Ryan never uses them. AI scatters them like confetti. The "not X — it's Y" construction with an em dash is basically an AI fingerprint.

**Semicolons in casual writing.** Most people avoid them. AI connects independent clauses with semicolons reflexively.

**The colon-then-list pattern.** "There are several key considerations: first, second, third." Real people just say the things.

### Word choice

The classic giveaways: "delve," "leverage," "utilize," "facilitate," "streamline," "robust," "holistic," "nuanced," "multifaceted," "landscape" (as metaphor for any domain).

Filler phrases: "It's important to note that," "It's worth noting that," "It bears mentioning that." These add nothing.

Transition crutches: "Additionally," "Furthermore," "Moreover," "Dive into," "Dive deeper." AI stacks conjunctive adverbs instead of just making the next point.

"Resonate" and "resonates with" appear far more in AI text than human text. Same with "straightforward."

### The reframe tic

AI loves the rhetorical pattern: "It's not X — it's Y." Dismiss the obvious framing, reframe with the "real" insight. A human writer might do this once in a piece for the big reveal. AI does it every other paragraph because training data is saturated with punchy opinion writing that uses this structure.

Examples from this repo (all AI-generated or AI-influenced):
- "The conflict isn't a bug — it's the fundamental nature of multi-stakeholder resource allocation"
- "The gap between xtraCHEF and R365 isn't a product gap — it's a category gap"
- "The problem isn't missing capability — it's that the automation drops messages silently"
- "This isn't a simple bug fix — it's a design flaw"

The pattern is seductive because it feels like insight. Sometimes it is. But when every paragraph does it, it stops being rhetoric and becomes a verbal tic.

### Structural tells

**Bullet lists for everything**, even when prose would be more natural. AI defaults to bullets because they're safe and organized. Human writers use bullets for reference material and comparison tables, prose for arguments. When you're using this guide you should default to prose.

**Suspicious balance**: every section has exactly 3-5 items. Real writing is lumpy.

**Relentless both-sides-ism**: "While X, it's also true that Y." AI hedges everything.

### Tone tells

**Too intense.** Everything is "exciting," "powerful," "transformative." A design spec is rarely transformative. That's OK.

**Eerie lack of personality.** No profanity, no humor, no genuine frustration. The text is smooth in a way that feels frictionless rather than polished. Instead, get loose! Have character.

---

## Part 2: How Ryan Writes

Based on analysis of: CLAUDE.md, exec-assistant-starter-prompt.md, ai-architect-interview-strategy.md, sr-eng-deploy-frequency-response.md, toastweb-ai-harness-design.md, ops-agent-one-pager.md, iam-team-payroll-context.md.

### The core quality

Ryan is an engineer, yes, but he went to liberal arts college at St. Lawrence University. He may not be the greatest writer but he works at his craft and his voice. He strives to be clear, specific, and opinionated. He's always trying to shorten pieces but struggling as he appreciates a narrative story. When writing like Ryan you should focus on telling stories and connecting thoughts. 


Ryan writes with a natural rhythm. He uses longer sentences that build through a complex idea, followed by shorter ones that land the point. The variation is what makes it sound like a person thinking out loud rather than a machine generating text.

**CAUTION:** Do not over-index on short sentences. Earlier versions of this guide said "short declarative sentences dominate" and the result was prose that sounded like a robot toddler. 

Paragraphs tend to open with the point and then support it, but this is a tendency, not a formula. He'll sometimes build to the point when the setup matters.

### What's absent from his writing

Almost no hedging language. No "it might be worth considering" or "one possible approach." When uncertain, he names the uncertainty directly ("we cannot definitively explain the corruption from the code") rather than hedging everything.

### Pet peeves

**"Just."** Ryan actively avoids it. "Just" minimizes whatever follows it and is often demeaning to the reader. "You just need to..." implies the thing is trivial and the person is dumb for not having done it already. Almost every sentence with "just" in it reads better without it. (Not an absolute rule, but close enough to treat as one when drafting.)

**"Obviously."** If it were actually obvious, you wouldn't need to write it. A sentence using "obviously" exists for the speaker's benefit, not the listener's. It's either demeaning (implying the reader should already know) or a waste of the reader's time (if they do already know). Cut it.

### Document structure

The first paragraph is the document. A great first paragraph is a great document. It should state the major point of the document and why the reader should care.

### The personality

**Informal and a little irreverent.** He'll end a rallying doc with "Giddy up." He described production data as "all fucked up" in a working session. He's not performing seriousness even when the situation is serious. There's a lightness to how he handles hard problems. He makes people want to work on the thing, not dread it. This directness is in pursuit of both his own personal voice and honesty toward the reader.

**Actually warm.** Ryan genuinely cares about his people and it shows in how he frames things. "I gave a pitch to the team before we hopped off the call to think about it for tomorrow." "After we get stable and I get some dinner." He includes the human moments. He's not writing a memo, he's talking to people he works with.

**Optimistic about hard problems.** "I think that we can make a ton of progress here." He doesn't sugarcoat the situation but he genuinely believes the team can fix it, and he says so. His docs leave you wanting to go do the thing, not feeling lectured at.

**Funny when it lands.** Not joke-funny, observation-funny. "That's archaeology, not engineering." He'll describe a broken system as a Rube Goldberg machine. The humor is in calling something exactly what it is when everyone else is dancing around it. He doesn't try to be funny, but when a line is right there he takes the shot.

**Code-switches by audience.** Informal and profane with peers in a working session. Clean and direct in docs to leadership. 