import { loadFont as loadPlexMono } from "@remotion/google-fonts/IBMPlexMono";
import { loadFont as loadPlexSans } from "@remotion/google-fonts/IBMPlexSans";

const plexMono = loadPlexMono();
const plexSans = loadPlexSans();

export const monoFontFamily = plexMono.fontFamily;
export const sansFontFamily = plexSans.fontFamily;
