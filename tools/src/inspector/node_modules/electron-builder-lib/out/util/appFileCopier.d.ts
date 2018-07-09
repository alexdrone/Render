/// <reference types="node" />
import { FileCopier, FileTransformer } from "builder-util/out/fs";
import { Stats } from "fs-extra-p";
import { Packager } from "../packager";
import { ResolvedFileSet } from "./AppFileCopierHelper";
export declare function getDestinationPath(file: string, fileSet: ResolvedFileSet): string;
export declare function copyAppFiles(fileSet: ResolvedFileSet, packager: Packager, transformer: FileTransformer): Promise<void>;
export declare function copyFileOrData(fileCopier: FileCopier, data: string | Buffer | undefined | null, source: string, destination: string, stats: Stats): Promise<void>;
