import type { MetadataRoute } from "next";

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "MediTag",
    short_name: "MediTag",
    description: "Scan a MediTag to see emergency medical info and call the person's family.",
    start_url: "/",
    display: "standalone",
    background_color: "#FAFAF8",
    theme_color: "#FAFAF8",
  };
}
