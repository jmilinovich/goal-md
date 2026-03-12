import { Composition } from "remotion";
import "./fonts";
import { GoalMdExplainer } from "./GoalMdExplainer";

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="GoalMdExplainer"
        component={GoalMdExplainer}
        durationInFrames={45 * 30}
        fps={30}
        width={1280}
        height={720}
      />
    </>
  );
};
