import React from "react";
import { createRoot } from "react-dom/client";
import { FluentProvider, webDarkTheme } from "@fluentui/react-components";
import { App } from "./App";
import { I18nProvider } from "./i18n";
import "./styles.css";

const container = document.getElementById("root");
if (!container) {
  throw new Error("Root container not found.");
}

const boot = async (): Promise<void> => {
  document.documentElement.classList.add("platform-solid");

  createRoot(container).render(
    <React.StrictMode>
      <FluentProvider theme={webDarkTheme}>
        <I18nProvider>
          <App />
        </I18nProvider>
      </FluentProvider>
    </React.StrictMode>
  );
};

void boot();
