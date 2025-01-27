require("FOXAPI.api")

-- This script should not be put into the FOXAPI modules folder!

--#REGION ˚♡ Configs ♡˚
FOXAPI.foxpat = {}
FOXAPI.foxpat.config = {
  --#REGION ˚♡ Simple ♡˚

	-- Looking for controls? They can be changed in-game from the Figura keybinds screen.

  swingArm = true,                 -- Whether patting should swing your arm. Recommended to turn this off when you set a pat animation.
  patAnimation = nil,              -- What animation should be played while you're patting.
  patParticle = "minecraft:heart", -- What particle should play while you're patting. Can be set to nil.

  playMobSounds = true,            -- Whether patting a mob plays a sound.
  mobSoundPitch = 1.5,             -- Set the pitch mob sounds will be played at.
  playNoteSounds = true,           -- Whether patting a player head plays the noteblock sound associated with that head.
  noteSoundPitch = 1.5,            -- Set the pitch player head noteblock sounds will be played at.

  requireCrouch = false,           -- Whether you have to be crouching after your first crouch to continue patting.
  requireEmptyHand = false,        -- Whether an empty hand is required for patting.
  requireEmptyOffHand = false,     -- Whether an empty offhand is required for patting.

  --#ENDREGION
  --#REGION ˚♡ Advanced ♡˚

  actAsInteractable = false, -- If you want another player to simply right click you or your player head without crouching or while holding an item.

  patDelay = 3,              -- How often patting should occur in ticks.
  holdFor = 10,              -- How long should it be after the last pat before you're considered no longer patting. Shouldn't be made less than patDelay.
  -- boundingBox = vec(0.6, 1.7999, 0.6), -- A custom bounding box that defines where people can pat you and the area that hearts get spawned on you.

  --#ENDREGION
}
--#ENDREGION