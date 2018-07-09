import { PlatformSpecificBuildOptions } from "./index";
export declare const excludedNames: string;
export interface GetFileMatchersOptions {
    readonly macroExpander: (pattern: string) => string;
    readonly customBuildOptions: PlatformSpecificBuildOptions;
    readonly outDir: string;
}
