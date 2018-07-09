import { Arch } from "builder-util";
import { MsiOptions } from "../";
import { Target } from "../core";
import { WinPackager } from "../winPackager";
export default class MsiTarget extends Target {
    private readonly packager;
    readonly outDir: string;
    private readonly vm;
    readonly options: MsiOptions;
    constructor(packager: WinPackager, outDir: string);
    build(appOutDir: string, arch: Arch): Promise<void>;
    private light(objectFiles, vm, artifactPath, appOutDir, vendorPath, tempDir);
    private getCommonWixArgs();
    private writeManifest(appOutDir, arch, commonOptions);
    private computeFileDeclaration(appOutDir);
}
