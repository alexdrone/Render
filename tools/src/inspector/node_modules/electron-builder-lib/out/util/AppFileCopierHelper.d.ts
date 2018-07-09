/// <reference types="node" />
import { FileTransformer } from "builder-util/out/fs";
import { Stats } from "fs-extra-p";
import { FileMatcher } from "../fileMatcher";
import { Packager } from "../packager";
export interface ResolvedFileSet {
    src: string;
    destination: string;
    files: Array<string>;
    metadata: Map<string, Stats>;
    transformedFiles?: Map<number, string | Buffer> | null;
}
export declare function computeFileSets(matchers: Array<FileMatcher>, transformer: FileTransformer | null, packager: Packager, isElectronCompile: boolean): Promise<Array<ResolvedFileSet>>;
export declare function ensureEndSlash(s: string): string;
