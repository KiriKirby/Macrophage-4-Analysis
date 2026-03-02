import { createContext, useContext, useMemo, useState, type ReactNode } from "react";
import {
  DEFAULT_LOCALE,
  createTranslator,
  type AppLocale,
  type MessageKey,
  type MessageParams
} from "../i18n";

interface I18nContextValue {
  locale: AppLocale;
  setLocale: (locale: AppLocale) => void;
  t: (key: MessageKey, params?: MessageParams) => string;
}

const I18nContext = createContext<I18nContextValue | null>(null);

interface I18nProviderProps {
  children: ReactNode;
  initialLocale?: AppLocale;
}

export function I18nProvider({ children, initialLocale = DEFAULT_LOCALE }: I18nProviderProps): JSX.Element {
  const [locale, setLocale] = useState<AppLocale>(initialLocale);

  const contextValue = useMemo<I18nContextValue>(() => {
    return {
      locale,
      setLocale,
      t: createTranslator(locale)
    };
  }, [locale]);

  return <I18nContext.Provider value={contextValue}>{children}</I18nContext.Provider>;
}

export function useI18n(): I18nContextValue {
  const ctx = useContext(I18nContext);
  if (!ctx) {
    throw new Error("useI18n must be used inside I18nProvider.");
  }
  return ctx;
}
