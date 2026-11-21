# SOUND CLASH BRAWL — Core Creative Identity & Development Guidelines

**Status:** Permanent creative direction, set by the owner (Garfield Connell), recorded 2026-11-19.
**Scope:** Guides all future development, character creation, animation, sound design and gameplay
decisions in the Godot 4.5 project.
**Authority:** Documentation only. This document changes no gameplay code, hitbox, timing value or
`/docs/` WebGL2 export file, and nothing listed as `[TODO]` is implemented.

Purpose: Establish the permanent creative direction for Sound Clash Brawl and guide all future development, character creation, animation, sound design, and gameplay decisions in our Godot 4.5 project.

## 1. The Foundation — Sound Clash Culture

• Sound Clash Brawl is an original fighting game built around authentic Jamaican sound clash culture—not a generic fighter with reggae aesthetics pasted on top.
• Traditional sound clashes involve competing sound systems, selectors, MCs, exclusive dubplates, DJ tags, musical strategy, crowd participation, and intense rivalry.
• The objective is to outclass, embarrass, overpower, and defeat the opposing sound through superior musical ammunition, performance, timing, and crowd response.

## 2. Authentic Sound Clash Dynamics, DJ Tags & Musical Ammunition

• The Mighty Crown Reference: Mighty Crown demonstrates how exclusive dubplates and selector swagger generate escalating crowd anticipation—every drop creates tension because the crowd doesn't know what ammunition comes next.
• Character DJ Tags & Dub-Echo Wheel-Ups (audio engine implemented 2026-11-21 with synthesised placeholders; **approved recordings still [TODO]**): Because each fighter is their own sound system, major hits and counter-attacks trigger echoing DJ vocal tags of the character's name (e.g., "FEEDBACK... Feedback... feedback..." echoing with dub delay right after smacking an opponent across the arena, answered by "L!CKSHOT... L!ckshot... l!ckshot..." when the opponent counter-attacks / wheels up!).
• "Plenty of Dubs" -> Bass-Dizzy Stun & "Tune-Fi-Tune" Counter ([TODO]): Dropping a dubplate special unleashes a sub-bass wave that inflicts a comedic musical dizzy stun (wobbly knees + spinning musical notes around the opponent's head) unless answered by a timed parry or counter-dub ("WHEEL AND COME AGAIN!").

## 3. Generations of Sound Clash Culture

• Reflects multiple generations of Jamaican sound-system history—drawing research inspiration from Stone Love, Bodyguard, Silver Hawk, Bass Odyssey, and Mighty Crown (never implying official affiliation).
• Different fighters represent different eras through fashion, cocky swagger, movement rhythm, and performance styles: Kangol and bucket hats, gold chains, long button-up shirts, Rasta mesh string vests, corduroy and olive cargo pants, Travel Fox footwear, Clarks Wallabees, oversized early-2000s streetwear, and contemporary dancehall fashion.
• Established character designs (Feedback, L!ckshot, L!kkle Moore) must remain consistent unless explicitly approved by the creator.

## 4. Combat & Signature Visual Presentation ([TODO] Future Polish — Do Not Implement Yet)

• Presentation draws inspiration from Marvel Tōkon (bold silhouettes, dimensional lighting, exaggerated anticipation/impact/recoil), DC team-fighting concepts (long-term [TODO] 2v2/3v3 crew switching—do not implement yet), Street Fighter 6 (layered stage depth & lighting), and Fatal Fury: City of the Wolves (arcade energy & expressive crowd reactions).
• Musical-Note Swing Trails ([TODO]): On heavy attacks, specials, and on-beat strikes, emit multicolored, varied-size musical notes flying along the arc of the attack gesture instead of generic slash lines (keeping light jabs clean so fast exchanges stay readable).
• 2.5D Rim Lighting & Impact Flash Frames ([TODO]): Subtle warm edge highlights and brief comic-ink impact flashes give 2D sprites dimensional depth without converting to 3D.
• Reactive Speaker Stacks & "Unplug That Sound!" Round Finish ([TODO]):
	• Speaker cones visibly flex harder as Hype rises.
	• When a fighter is knocked out at the end of a round, their speaker stack emits smoke, electrical sparks, and tilts/topples, while their sound literally gets unplugged—playing an unmistakable power-down / plug-pull audio cue ("UNPLUG THAT SOUND!") as a disappointed crew member in the background pulls the cord and begins packing up (resetting cleanly between rounds).
• "Lightah!" Crowd-Judge Finishes ([TODO]): Devastating hits and disrespect moves trigger raised lighters, waving rags, airhorn blasts, and individualized crowd reactions (never uniform bouncing loops).

## 5. Character Movement — Creator-Led Animation Workflow

• Every fighter will ultimately be recognizable by their distinctive walking style, idle stance, movement rhythm, and silhouette alone.
• Strict Workflow Rule: The creator and creative AI tools (Google Flow, Spriteriffic, Gemini, ChatGPT) develop, generate, review, and approve original walking animations and pose references first. Freebuff must NOT invent or independently generate initial character walks.
• Once approved and uploaded, Freebuff imports them, aligns baselines (y = 592), refines transitions/timing, and verifies gameplay behavior.
• Feedback: Preserve his established skanking-inspired walk, 132 BPM rhythmic bounce, right-hand corded mic, and approved visual identity.
• L!ckshot: His original signature walk is the next creator-led animation task (creator + Google Flow / AI tools will approve his walk before handing sprites to Freebuff).

## 6. Sound Design — A Major Creative Priority

• Explore original dubplate-inspired recordings, echoing character DJ tags, selector/MC callouts, 132 BPM dancehall/reggae riddims, sound-system sirens/power-downs, crowd forwards/whistles/laughter, and character-specific voice expressions—using strictly original, licensed, or creator-approved recordings.

### 2026-11-21 status note — 3D presentation

The 2.5D rim-light, impact-frame and musical-note-trail ideas in §4 are now implemented, and the
fighter presentation has moved to a **3D cel-shaded / inked** layer on a Node3D yard with real
DirectionalLight3D + SpotLight3D afternoon/sunset/night rigs. The combat simulation, hitboxes,
input handling, Patois callouts and round flow are unchanged. This is implementation status, not
new creative approval: the owner has not seen the rendered 3D build yet.

## 8. Recorded Future Backlog — 2026-11-21 (Record Only — Do Not Implement Yet)

These three items are recorded at the owner's request and are **not built**. They change no code,
scene, hitbox, timing value or `/docs/` export file. They live here permanently alongside the
creative direction so a later session can pick one up without re-deciding the concept.

### [TODO] B13 — Toronto Selector Party & Jukebox Mode

Standalone Title Menu mode celebrating Toronto's multicultural party melting pot (Reggae,
Dancehall, Hip-Hop, R&B, House and Soca). Players pick a 3D selector (Feedback, L!ckshot,
L!kkle Moore) to dance/skank behind the 3D speaker stacks and talk DJ-style over tracks, with
automatic music ducking and tape-delay mic echo, and can trigger manual **PULL UP! / WHEEL UP!**
rewinds and airhorns. Strictly creator-owned tracks may be streamed and one-click downloaded from
`docs/tracks/`; users may also load local audio files for 100% client-side, in-browser RAM playback
only. **Copyright safeguard:** user files are NEVER uploaded to any server, stored remotely, or
distributed to other players.

### [TODO] B14 — "World Clash" Arcade Tour & International Bookings

Classic fighting-game world ladder with lightweight promoter-booking progression — never an open
world — where winning clashes unlocks international bookings from Jamaica (Home Beach Arena) to
Toronto, Montreal, New York, London (England) and Japan, each with a distinct 3D stage atmosphere
and an international rival.

### [TODO] B15 — Panicking Promoter Commentator & Personal Crowd Shout-Outs

Reactive event-promoter voice slot who panics whenever fighters collide near the speaker stacks
("Dat coming out yuh fee!", "Yuh nah get paid fi dat!", "Me never booking yuh sound again!"), plus
creator-approved crowd shout-out slots dedicated to real-life friends, family and local supporters
(with their permission, avoiding unapproved celebrity names).

## 9. Research, Cultural Accuracy & Permanent Development Principles

• Prioritize primary cultural references and the creator's lived cultural knowledge—never reduce sound clash culture to superficial stereotypes.
• Follow the 10 Permanent Development Principles: (1) Sound clash culture is the foundation; (2) Epic fighting is the primary gameplay; (3) Character designs stay consistent; (4) Original animations are creator-led; (5) Cultural authenticity informs gameplay, sound, and personality; (6) Existing Godot 4.5 systems are not unnecessarily replaced; (7) Major creative changes require creator approval; (8) New features are added incrementally and verified; (9) Preserve humour, Jamaican expressions, and competitive swagger; (10) Avoid superficial stereotypes.
