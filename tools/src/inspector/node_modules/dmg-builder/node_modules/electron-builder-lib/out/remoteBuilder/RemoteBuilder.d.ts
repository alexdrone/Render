import { Arch } from "builder-util";
import { Target } from "../core";
import { PlatformPackager } from "../platformPackager";
import { ArtifactInfo } from "./RemoteBuildManager";
export declare class RemoteBuilder {
    readonly packager: PlatformPackager<any>;
    private readonly toBuild;
    private buildStarted;
    constructor(packager: PlatformPackager<any>);
    scheduleBuild(target: Target, arch: Arch, unpackedDirectory: string): void;
    build(): Promise<any>;
    private _build(targets, packager);
}
export interface RemoteBuilderResponse {
    files: Array<ArtifactInfo> | null;
    error: string | null;
}
