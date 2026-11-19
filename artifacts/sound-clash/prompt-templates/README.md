# Character & art prompt templates

Locked, copy-pasteable appearance blocks for image generation. **Never rewrite a character
description from scratch** — paste the block below verbatim, then append only the pose/action
line for the frame you need. The character block is what keeps outfits, props and proportions
identical between uploads; changing a word in it changes the fighter.

Maintained by: Garfield Connell (owner, final visual approver). Registered in `AGENTS.md` §5 and
§9. This folder is documentation only: it adds no art and approves none.

## How to use

1. Copy the fighter's block from below, exactly as written.
2. Append one short pose line (for example `Pose: deep lean-back groove, weight on the back
   foot, free hand open.`) — do not restate or "improve" the outfit.
3. Keep the output rules in every prompt.
4. Square canvas, one figure, full body from crown to sole, nothing cropped.
5. Save the upload untouched; processing and floor alignment happen in
   `art-source/fighters/prep_lickshot_poses.py` (white-background mode) or
   `artifacts/sound-clash/art-source/feedback/prep_feedback_poses_2026-11-18.py`, not by hand.

## Output rules (include in every prompt)

- Pure **#FFFFFF** background, flat white, with **zero floor shadow** and no cast shadow,
  no gradient, no vignette, no scenery, no props that the character is not holding.
- One figure only. No text, logos, watermarks or UI.
- Exactly the declared outfit, colours, shoe construction and props — no redesigns.
- Two arms, two legs, five fingers per hand, one head. No extra or merged limbs.
- Do not mirror the art to fake a left-facing pose. The declared hand holds the mic.
- Full body visible: crown of the head through the soles of both shoes.

## Feedback — Fighter #1

Identity: slim build, face concealed by the hat brim, one gold tooth only when the mouth is open,
never white hair streaks or braids replacing the locks.

```text
Full-body 2D fighting-game character illustration of Feedback, a lean slim Jamaican sound-system
selecta. Burgundy/maroon bucket hat pulled low over the eyes so the face is concealed, original
thick dark dreadlocks under the hat. Burgundy/maroon track jacket with cream sleeve stripes,
fitted dark trousers, tan suede Clarks Wallabees with the moccasin apron seam, lacing and crepe
sole. Right hand holds a silver corded microphone, the thin black mic cable runs from the mic into
the jacket. Exactly one microphone, one cable, no second mic. Pure #FFFFFF background, flat white,
zero floor shadow and no cast shadow, no gradient, no scenery. One figure, full body from the crown
of the hat to the soles of both shoes, square canvas, no text or watermark.
```

## L!ckshot — Fighter #2

Internal folder and code id stay `lickshot`; the on-screen name renders **L!CKSHOT** under the
I → ! rule.

```text
Full-body 2D fighting-game character illustration of Lickshot, a Jamaican dancehall MC. Brown
Kangol flat cap worn low over the eyes, short dreadlocks, goatee, one gold tooth. Red, yellow and
green Rasta mesh string vest (no jacket, bare arms), gold chain, olive cargo trousers, tan suede
Clarks Wallabees with the moccasin apron seam and crepe sole. Right hand holds a silver corded
microphone, the thin black mic cable runs from the mic and trails to the floor. Exactly one
microphone, one cable, no second mic. Pure #FFFFFF background, flat white, zero floor shadow and no
cast shadow, no gradient, no scenery. One figure, full body from the crown of the cap to the soles
of both shoes, square canvas, no text or watermark.
```

## Likkle Moore — Fighter #3

Displays as **L!KKLE MOORE**. Internal key stays `young_selecta` and the sprite folder stays
`assets/sprites/young-selecta/`; the name may still evolve.

```text
Full-body 2D fighting-game character illustration of Likkle Moore, a 10-year-old Black boy and
schoolyard DJ prodigy. Crisp low fade haircut, dark-blue rectangular glasses, patterned
durag/bandana. Cream school-uniform button-down shirt, navy trousers, crisp white sneakers,
oversized blue DJ/school gadget backpack worn on both shoulders. Pure #FFFFFF background, flat
white, zero floor shadow and no cast shadow, no gradient, no scenery. One figure, full body from
the top of the head to the soles of both sneakers, square canvas, no text or watermark.
```

## Consistency notes that are not negotiable

- **Feedback:** bucket hat over the eyes, one mic in the right hand, cable into the jacket,
  Clarks Wallabees, no extra gold tooth.
- **L!ckshot:** Kangol flat cap low, string vest with no jacket, right-hand mic, Clarks Wallabees.
- **Likkle Moore:** child proportions (about 82 % of an adult fighter's height), low fade, glasses,
  durag/bandana, cream shirt, navy trousers, white sneakers, blue backpack.
- A generated frame is a **candidate**: it still needs the owner's visual approval, background
  keying, the 512 px cap and the y 592 floor alignment before it can be wired into `BaseFighter`.
- Do not ask a generator for a pose the fighter already has an approved drawing for; match the
  existing silhouette instead.
