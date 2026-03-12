import { AbsoluteFill, useCurrentFrame, interpolate, spring, useVideoConfig } from "remotion";
import { colors, mono, heading, sans, FRAMES_PER_BEAT, FRAME_PADDING, centeredContent, FONT_SIZES } from "../styles";

interface ElementCardProps {
  title: string;
  icon: string;
  description: string;
  accent: string;
  delay: number;
}

const ElementCard: React.FC<ElementCardProps> = ({ title, icon, description, accent, delay }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const appear = spring({
    frame: frame - delay,
    fps,
    config: { damping: 16, stiffness: 120, mass: 0.8 },
  });

  return (
    <div
      style={{
        opacity: interpolate(appear, [0, 1], [0, 1]),
        transform: `translateY(${interpolate(appear, [0, 1], [30, 0])}px)`,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        width: 210,
        textAlign: "center",
      }}
    >
      <div
        style={{
          ...mono,
          fontSize: 42,
          marginBottom: 18,
          width: 96,
          height: 96,
          borderRadius: 24,
          backgroundColor: `${accent}0A`,
          border: `2px solid ${accent}30`,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          color: accent,
          fontWeight: 700,
        }}
      >
        {icon}
      </div>
      <div style={{ ...heading, fontSize: FONT_SIZES.label, color: colors.text, marginBottom: 8 }}>
        {title}
      </div>
      <div style={{ ...sans, fontSize: FONT_SIZES.small, color: colors.textDim, lineHeight: 1.6, fontWeight: 400 }}>
        {description}
      </div>
    </div>
  );
};

const elements = [
  { title: "Fitness Function", icon: "#", description: "A script that outputs a number. Not a vibe.", accent: colors.blue },
  { title: "Improvement Loop", icon: "\u21BB", description: "Measure, diagnose, act, verify, keep or revert.", accent: colors.green },
  { title: "Action Catalog", icon: "\u2630", description: "Concrete moves ranked by impact.", accent: colors.amber },
  { title: "Operating Mode", icon: "\u25B6", description: "Converge, continuous, or supervised.", accent: colors.blue },
  { title: "Constraints", icon: "\u2715", description: "Lines the agent must not cross.", accent: colors.red },
];

export const Scene3Elements: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const titleSpring = spring({ frame, fps, config: { damping: 22, stiffness: 100 } });
  const subSpring = spring({ frame: frame - FRAMES_PER_BEAT, fps, config: { damping: 20, stiffness: 90 } });

  const cardStart = FRAMES_PER_BEAT * 3;
  const cardStagger = FRAMES_PER_BEAT * 1.5;

  const loopDelay = cardStart + cardStagger * 5 + FRAMES_PER_BEAT * 2;
  const loopSpring = spring({ frame: frame - loopDelay, fps, config: { damping: 18, stiffness: 80 } });

  const loopWords = ["measure", "diagnose", "act", "verify", "keep | revert"];
  const loopColors = [colors.blue, colors.text, colors.amber, colors.green, colors.textDim];

  return (
    <AbsoluteFill style={{ backgroundColor: colors.bg }}>
      <AbsoluteFill
        style={{
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          padding: `0 ${FRAME_PADDING}px`,
        }}
      >
        {/* Title */}
        <div
          style={{
            ...heading,
            fontSize: FONT_SIZES.title + 4,
            textAlign: "center",
            opacity: interpolate(titleSpring, [0, 1], [0, 1]),
            transform: `translateY(${interpolate(titleSpring, [0, 1], [10, 0])}px)`,
            marginBottom: 12,
          }}
        >
          five elements. one file.
        </div>

        {/* Subtitle */}
        <div
          style={{
            ...sans,
            fontSize: FONT_SIZES.body,
            fontWeight: 400,
            textAlign: "center",
            color: colors.textDim,
            opacity: interpolate(subSpring, [0, 1], [0, 1]),
            transform: `translateY(${interpolate(subSpring, [0, 1], [8, 0])}px)`,
            marginBottom: 48,
          }}
        >
          everything an agent needs to work autonomously
        </div>

        {/* Cards — evenly distributed */}
        <div
          style={{
            display: "flex",
            justifyContent: "center",
            gap: 24,
            marginBottom: 56,
          }}
        >
          {elements.map((el, i) => (
            <ElementCard
              key={el.title}
              {...el}
              delay={cardStart + i * cardStagger}
            />
          ))}
        </div>

        {/* Loop flow */}
        <div
          style={{
            ...mono,
            textAlign: "center",
            fontSize: FONT_SIZES.body,
            opacity: interpolate(loopSpring, [0, 1], [0, 1]),
            transform: `translateY(${interpolate(loopSpring, [0, 1], [10, 0])}px)`,
          }}
        >
          {loopWords.map((word, i) => (
            <span key={word}>
              {i > 0 && <span style={{ color: colors.muted }}> {"\u2192"} </span>}
              <span style={{ color: loopColors[i], fontWeight: 600 }}>{word}</span>
            </span>
          ))}
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
