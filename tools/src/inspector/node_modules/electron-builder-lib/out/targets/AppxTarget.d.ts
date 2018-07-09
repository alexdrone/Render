import { Arch } from "builder-util";
import { AppXOptions } from "../";
import { Target } from "../core";
import { WinPackager } from "../winPackager";
export default class AppXTarget extends Target {
    private readonly packager;
    readonly outDir: string;
    readonly options: AppXOptions;
    constructor(packager: WinPackager, outDir: string);
    build(appOutDir: string, arch: Arch): Promise<any>;
    private static computeUserAssets(vm, vendorPath, userAssetDir);
    private computePublisherName();
    private writeManifest(templatePath, outFile, arch, publisher, userAssets);
}
