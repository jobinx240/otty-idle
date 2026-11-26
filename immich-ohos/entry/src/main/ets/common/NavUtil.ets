import { UIContext } from '@kit.ArkUI';

/**
 * UIContext router helpers (module-level router APIs are deprecated on API 24+).
 */
export class NavUtil {
  static replace(ui: UIContext, url: string): void {
    ui.getRouter().replaceUrl({ url: url });
  }

  static push(ui: UIContext, url: string, params?: Object): void {
    if (params) {
      ui.getRouter().pushUrl({ url: url, params: params });
    } else {
      ui.getRouter().pushUrl({ url: url });
    }
  }

  static back(ui: UIContext): void {
    ui.getRouter().back();
  }

  static params<T>(ui: UIContext): T {
    return ui.getRouter().getParams() as T;
  }
}
