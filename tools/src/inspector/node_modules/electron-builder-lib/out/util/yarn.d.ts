import { Lazy } from "lazy-val";
import { Configuration } from "../configuration";
import { Dependency } from "./packageDependencies";
export declare function installOrRebuild(config: Configuration, appDir: string, options: RebuildOptions, forceInstall?: boolean): Promise<void>;
export interface DesktopFrameworkInfo {
    version: string;
    useCustomDist: boolean;
}
export declare function getGypEnv(frameworkInfo: DesktopFrameworkInfo, platform: string, arch: string, buildFromSource: boolean): {
    npm_config_arch: string;
    npm_config_target_arch: string;
    npm_config_platform: string;
    npm_config_build_from_source: boolean;
    npm_config_target_platform: string;
    npm_config_update_binary: boolean;
    npm_config_fallback_to_build: boolean;
} | {
    npm_config_disturl: string;
    npm_config_target: string;
    npm_config_runtime: string;
    npm_config_devdir: string;
    npm_config_arch: string;
    npm_config_target_arch: string;
    npm_config_platform: string;
    npm_config_build_from_source: boolean;
    npm_config_target_platform: string;
    npm_config_update_binary: boolean;
    npm_config_fallback_to_build: boolean;
};
export interface RebuildOptions {
    frameworkInfo: DesktopFrameworkInfo;
    productionDeps?: Lazy<Array<Dependency>>;
    platform?: string;
    arch?: string;
    buildFromSource?: boolean;
    additionalArgs?: Array<string> | null;
}
