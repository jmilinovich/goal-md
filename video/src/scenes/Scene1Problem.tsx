import { AbsoluteFill, useCurrentFrame, interpolate, spring, useVideoConfig } from "remotion";
import { colors, mono, heading, sans, FRAMES_PER_BEAT, FRAME_PADDING, centeredContent, FONT_SIZES } from "../styles";

const questions = [
  { text: "are my docs actually good?", color: colors.textDim },
  { text: "is my test suite trustworthy?", color: colors.textDim },
  { text: "is this API reliable under real load?", color: colors.textDim },
];

export const Scene1Problem: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Gentle fade in
  const titleOpacity = interpolate(frame, [0, 20], [0, 1], { extrapolateRight: "clamp" });
  const titleY = spring({ frame, fps, config: { damping: 24, stiffness: 100, mass: 1 } });

  // Questions appear staggered
  const q1Frame = FRAMES_PER_BEAT * 3;
  const q2Frame = FRAMES_PER_BEAT * 5;
  const q3Frame = FRAMES_PER_BEAT * 7;
  const qFrames = [q1Frame, q2Frame, q3Frame];

  // "no number" label appears after the questions
  const noNumberFrame = FRAMES_PER_BEAT * 9;
  const noNumberSpring = spring({
    frame: frame - noNumberFrame,
    fps,
    config: { damping: 16, stiffness: 120, mass: 0.8 },
  });

  const questionFrame = FRAMES_PER_BEAT * 11;
  const questionSpring = spring({
    frame: frame - questionFrame,
    fps,
    config: { damping: 16, stiffness: 120, mass: 0.8 },
  });

  const lineOpacity = (startFrame: number) =>
    interpolate(frame, [startFrame, startFrame + 10], [0, 1], { extrapolateRight: "clamp" });

  const lineY = (startFrame: number) => {
    const s = spring({
      frame: frame - startFrame,
      fps,
      config: { damping: 20, stiffness: 100, mass: 0.8 },
    });
    return interpolate(s, [0, 1], [14, 0]);
  };

  return (
    <AbsoluteFill style={{ backgroundColor: colors.bg }}>
      {/* Title */}
      <div
        style={{
          ...centeredContent,
          ...heading,
          fontSize: FONT_SIZES.title,
          opacity: titleOpacity,
          transform: `translateY(${interpolate(titleY, [0, 1], [12, 0])}px)`,
          top: 100,
          textAlign: "center",
        }}
      >
        <span style={{ color: colors.textDim }}>some things don't have </span>
        <span style={{ color: colors.red, fontWeight: 800 }}>numbers</span>
      </div>

      {/* Questions — each appears like a thought the viewer recognizes */}
      <div
        style={{
          ...centeredContent,
          top: 220,
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          gap: 28,
        }}
      >
        {questions.map((q, i) => (
          frame > qFrames[i] && (
            <div
              key={q.text}
              style={{
                ...sans,
                fontSize: FONT_SIZES.heading,
                fontWeight: 500,
                fontStyle: "italic",
                color: q.color,
                opacity: lineOpacity(qFrames[i]),
                transform: `translateY(${lineY(qFrames[i])}px)`,
                textAlign: "center",
              }}
            >
              "{q.text}"
            </div>
          )
        ))}

        {/* The punchline — these have no metric */}
        {frame > noNumberFrame && (
          <div
            style={{
              ...mono,
              fontSize: FONT_SIZES.body,
              color: colors.muted,
              marginTop: 12,
              opacity: interpolate(noNumberSpring, [0, 1], [0, 1]),
              transform: `translateY(${interpolate(noNumberSpring, [0, 1], [8, 0])}px)`,
              textAlign: "center",
            }}
          >
            no test runner gives you a score for these
          </div>
        )}
      </div>

      {/* Bottom question */}
      {frame > questionFrame && (
        <div
          style={{
            ...centeredContent,
            bottom: 80,
            textAlign: "center",
          }}
        >
          <div
            style={{
              ...heading,
              fontSize: FONT_SIZES.heading,
              opacity: interpolate(questionSpring, [0, 1], [0, 1]),
              transform: `translateY(${interpolate(questionSpring, [0, 1], [10, 0])}px)`,
            }}
          >
            <span style={{ color: colors.textDim }}>what if you could </span>
            <span style={{ color: colors.blue, fontStyle: "italic" }}>construct</span>
            <span style={{ color: colors.textDim }}> a metric?</span>
          </div>
          {/* Lineage hint */}
          <div
            style={{
              ...sans,
              fontSize: FONT_SIZES.caption,
              color: colors.muted,
              marginTop: 10,
              fontWeight: 400,
              opacity: interpolate(frame, [questionFrame + 15, questionFrame + 30], [0, 1], { extrapolateRight: "clamp" }),
            }}
          >
            Karpathy's autoresearch proved: agent + fitness function + loop = breakthroughs
          </div>
        </div>
      )}
    </AbsoluteFill>
  );
};
