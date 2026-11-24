import { image } from '@kit.ImageKit';
import { HttpClient, HttpError, immichHttp } from './HttpClient';

/**
 * Downloads Immich thumbnails with auth headers and keeps an in-memory PixelMap cache.
 */
export class ThumbnailLoader {
  private http: HttpClient;
  private cache: Map<string, image.PixelMap> = new Map();
  private inflight: Map<string, Promise<image.PixelMap | undefined>> = new Map();

  constructor(http: HttpClient = immichHttp) {
    this.http = http;
  }

  async load(assetId: string, size: string = 'thumbnail'): Promise<image.PixelMap | undefined> {
    const key = `${assetId}:${size}`;
    const cached = this.cache.get(key);
    if (cached) {
      return cached;
    }

    const pending = this.inflight.get(key);
    if (pending) {
      return pending;
    }

    const task = this.fetch(assetId, size, key);
    this.inflight.set(key, task);
    try {
      return await task;
    } finally {
      this.inflight.delete(key);
    }
  }

  clear(): void {
    this.cache.forEach((pixelMap: image.PixelMap) => {
      try {
        pixelMap.release();
      } catch (_e) {
        // ignore
      }
    });
    this.cache.clear();
  }

  private async fetch(
    assetId: string,
    size: string,
    key: string
  ): Promise<image.PixelMap | undefined> {
    try {
      const bytes = await this.http.getArrayBuffer(`/assets/${assetId}/thumbnail`, { 'size': size });
      const source = image.createImageSource(bytes);
      // Let the decoder pick native size; forced upscale of tiny test assets can fail.
      const pixelMap = await source.createPixelMap();
      source.release();
      if (pixelMap) {
        // Bound cache size for personal MVP.
        if (this.cache.size > 200) {
          const firstKey = this.cache.keys().next().value as string;
          const old = this.cache.get(firstKey);
          this.cache.delete(firstKey);
          if (old) {
            try {
              old.release();
            } catch (_e) {
              // ignore
            }
          }
        }
        this.cache.set(key, pixelMap);
      }
      return pixelMap;
    } catch (e) {
      if (e instanceof HttpError) {
        return undefined;
      }
      return undefined;
    }
  }
}

export const thumbnailLoader: ThumbnailLoader = new ThumbnailLoader();
