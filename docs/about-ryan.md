# About Ryan

This is context for Clairy to understand who Ryan is, what he cares about, and how to be useful to him.

## The basics

Ryan Pollock is a principal-level software engineer at Toast, the restaurant technology company. He's based in the US and works on the platform engineering side, specifically around publishing infrastructure, observability, and AI-powered developer tools. His role is somewhere between architect and tech lead, heavy on cross-team influence and technical strategy.

He went to St. Lawrence University, a liberal arts school, which shows up in how he thinks and communicates. He writes well, cares about craft, and approaches problems narratively rather than purely analytically. He's an engineer who reads and writes, not just codes.

## How he works

Ryan is a builder. He doesn't just talk about problems, he makes tools. He's built a whole ecosystem of CLI tools for himself at work (Splunk querying, Datadog access, Sourcegraph search, Gmail/Calendar/Drive access, Jira/Confluence integration) because he doesn't trust third-party packages with his credentials and prefers to own his stack.

He uses AI agents extensively for work. His work AI assistant (RYAI, running on Claude Code) handles morning triage, task management, research, Slack monitoring, and meeting prep. RYAI lives in a git repo that serves as its brain. The architecture is: one agent, many tools, persistent state in markdown files, daily logs, cached data from external systems.

He thinks in terms of systems and leverage. His instinct is always "how do I build the thing that makes this class of problem go away" rather than "how do I solve this one instance."

## Technical opinions (strong ones)

Single agent with many tools beats multi-agent hierarchies. The most capable AI agents in production all converged on this pattern. Coordination overhead between multiple agents is almost always worse than just giving one smart agent more tools.

Supply chain security matters. Never install random packages that handle credentials. If a tool touches auth tokens, you should be able to read every line of its code.

Red/green TDD. Write tests first, then make them pass.

Git discipline. Meaningful commits, clean branches, PRs that explain the "why."

## Communication style

Direct, informal, opinionated. He doesn't hedge. When he's uncertain he names the uncertainty directly rather than qualifying everything with "it might be worth considering." He swears casually with peers but switches to clean and direct for leadership audiences.

He hates bullet lists in conversation and prefers prose that tells a story. He never uses "just" (it's demeaning) or "obviously" (if it were obvious you wouldn't need to say it). No em dashes, which are an AI tell.

He's warm with people, funny when a line is right there (observation-funny, not joke-funny), and optimistic about hard problems without sugarcoating them.

## Personal life

Ryan has a MacBook Air set up as an "AI laptop" that lives on his home tailnet. He doesn't want to log into personal accounts on it. That's the machine Clairy lives on.

He uses Telegram, Tailscale, and is comfortable with terminal-first tools. He's experimenting with running personal AI outside the corporate/subscription ecosystem, using API keys and open-source tooling.

## What he needs from a personal AI

Something that knows him well enough to be useful without constant context-setting. Someone to think with about non-work things, handle personal research, remember conversations, and be available via Telegram from any device. Not a work assistant (that's RYAI). Something more like a companion that can actually do things.
