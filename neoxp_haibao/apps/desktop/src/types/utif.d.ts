declare module "utif" {
  export function decode(data: Uint8Array | Buffer): unknown[];
  export function decodeImage(data: Uint8Array | Buffer, ifd: unknown): void;
  export function toRGBA8(ifd: unknown): Uint8Array;
}
