import { zhCNMessages } from "./messages.zh-CN";

export const LOCALES = ["zh-CN"] as const;
export type AppLocale = (typeof LOCALES)[number];
export const DEFAULT_LOCALE: AppLocale = "zh-CN";

const catalogs = {
  "zh-CN": zhCNMessages
} as const;

export type MessageKey = keyof typeof zhCNMessages;
export type MessageParams = Record<string, string | number>;

function applyParams(template: string, params?: MessageParams): string {
  if (!params) return template;
  let out = template;
  const keys = Object.keys(params);
  for (const key of keys) {
    const value = String(params[key]);
    out = out.replaceAll(`{${key}}`, value);
  }
  return out;
}

export function createTranslator(locale: AppLocale) {
  const catalog = catalogs[locale];
  return (key: MessageKey, params?: MessageParams): string => {
    const template = catalog[key] ?? catalogs[DEFAULT_LOCALE][key] ?? key;
    return applyParams(template, params);
  };
}
