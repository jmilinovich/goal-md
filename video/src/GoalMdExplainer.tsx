import React from "react";
import { AbsoluteFill, Audio, interpolate, Sequence, staticFile, useCurrentFrame } from "remotion";
import { Scene1Problem } from "./scenes/Scene1Problem";
import { Scene2Story } from "./scenes/Scene2Story";
import { Scene3Elements } from "./scenes/Scene3Elements";
import { Scene4GoToSleep } from "./scenes/Scene4GoToSleep";
import { colors } from "./styles";

const CROSSFADE_FRAMES = 15;

/**
 * FadeTransition — crossfade wrapper that applies fadeIn at the start
 * and fadeOut at the end of a scene. Scenes overlap by CROSSFADE_FRAMES
 * so the outgoing scene fades out while the incoming scene fades in.
 */
const FadeTransition: React.FC<{
  children: React.ReactNode;
  durationInFrames: number;
  isFirst?: boolean;
  isLast?: boolean;
}> = ({ children, durationInFrames, isFirst = false, isLast = false }) => {
  const frame = useCurrentFrame();

  // fadeIn: ramp opacity 0→1 over CROSSFADE_FRAMES at the start (skip for first scene)
  const fadeIn = isFirst
    ? 1
    : interpolate(frame, [0, CROSSFADE_FRAMES], [0, 1], {
        extrapolateLeft: "clamp",
        extrapolateRight: "clamp",
      });

  // fadeOut: ramp opacity 1→0 over CROSSFADE_FRAMES at the end (skip for last scene)
  const fadeOut = isLast
    ? 1
    : interpolate(
        frame,
        [durationInFrames - CROSSFADE_FRAMES, durationInFrames],
        [1, 0],
        { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
      );

  return (
    <AbsoluteFill style={{ opacity: fadeIn * fadeOut }}>
      {children}
    </AbsoluteFill>
  );
};

const AudioWithFade: React.FC = () => {
  const frame = useCurrentFrame();
  const totalFrames = 45 * 30; // 1350
  // Fade out over last 3 seconds (90 frames)
  const volume = interpolate(frame, [0, 30, totalFrames - 90, totalFrames], [0, 0.5, 0.5, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  return <Audio src={staticFile("music.mp3")} volume={volume} />;
};

export const GoalMdExplainer: React.FC = () => {
  const fps = 30;

  // Scene durations (including crossfade overlap with next scene)
  const s1Duration = 8 * fps + CROSSFADE_FRAMES;
  const s2Duration = 12 * fps + CROSSFADE_FRAMES;
  const s3Duration = 15 * fps + CROSSFADE_FRAMES;
  const s4Duration = 10 * fps;

  // Scene start times: each starts CROSSFADE_FRAMES before the previous ends
  const s1Start = 0;
  const s2Start = 8 * fps;
  const s3Start = 20 * fps;
  const s4Start = 35 * fps;

  return (
    <AbsoluteFill style={{ backgroundColor: colors.bg }}>
      {/* Ambient audio with fade in/out */}
      <AudioWithFade />

      {/* Scene 1: The Problem (0-8s + crossfade overlap) */}
      <Sequence from={s1Start} durationInFrames={s1Duration}>
        <FadeTransition durationInFrames={s1Duration} isFirst>
          <Scene1Problem />
        </FadeTransition>
      </Sequence>

      {/* Scene 2: The Story — autoresearch lineage (8-20s + crossfade overlap) */}
      <Sequence from={s2Start} durationInFrames={s2Duration}>
        <FadeTransition durationInFrames={s2Duration}>
          <Scene2Story />
        </FadeTransition>
      </Sequence>

      {/* Scene 3: The Five Elements (20-35s + crossfade overlap) */}
      <Sequence from={s3Start} durationInFrames={s3Duration}>
        <FadeTransition durationInFrames={s3Duration}>
          <Scene3Elements />
        </FadeTransition>
      </Sequence>

      {/* Scene 4: Go To Sleep (35-45s) */}
      <Sequence from={s4Start} durationInFrames={s4Duration}>
        <FadeTransition durationInFrames={s4Duration} isLast>
          <Scene4GoToSleep />
        </FadeTransition>
      </Sequence>
    </AbsoluteFill>
  );
};
