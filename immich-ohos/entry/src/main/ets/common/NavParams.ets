/** Router params for album detail. */
export class AlbumRouteParams {
  albumId: string;
  albumName: string;

  constructor(albumId: string, albumName: string) {
    this.albumId = albumId;
    this.albumName = albumName;
  }
}

/** Router params for asset viewer. */
export class AssetRouteParams {
  assetId: string;

  constructor(assetId: string) {
    this.assetId = assetId;
  }
}

/** Router params for person → search page. */
export class PersonRouteParams {
  personId: string;
  personName: string;

  constructor(personId: string, personName: string) {
    this.personId = personId;
    this.personName = personName;
  }
}
