/// <reference types="node" />
import { UploadTask } from "electron-publish";
import { OutgoingHttpHeaders, SecureClientSessionOptions } from "http2";
import { PlatformPackager } from "../platformPackager";
import { ProjectInfoManager } from "./ProjectInfoManager";
import { RemoteBuilderResponse } from "./RemoteBuilder";
export declare function getConnectOptions(): SecureClientSessionOptions;
export declare class RemoteBuildManager {
    private readonly buildServiceEndpoint;
    private readonly projectInfoManager;
    private readonly unpackedDirectory;
    private readonly outDir;
    private readonly packager;
    private readonly client;
    constructor(buildServiceEndpoint: string, projectInfoManager: ProjectInfoManager, unpackedDirectory: string, outDir: string, packager: PlatformPackager<any>);
    build(customHeaders: OutgoingHttpHeaders): Promise<RemoteBuilderResponse | null>;
    private doBuild(customHeaders);
    private downloadArtifacts(files, fileSizes, baseUrl);
    private artifactInfoToArtifactCreatedEvent(artifact, localFile);
    private uploadUnpackedAppArchive(stream, zstdCompressionLevel, reject);
}
export declare function checkStatus(status: number, reject: (error: Error) => void): boolean;
export interface ArtifactInfo extends UploadTask {
    target: string | null;
    readonly isWriteUpdateInfo?: boolean;
    readonly updateInfo?: any;
}
