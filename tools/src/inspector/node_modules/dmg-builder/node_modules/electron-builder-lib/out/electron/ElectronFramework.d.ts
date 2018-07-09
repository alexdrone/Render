import { Configuration } from "../configuration";
import { Framework } from "../Framework";
import { Packager } from "../packager";
export declare function createElectronFrameworkSupport(configuration: Configuration, packager: Packager): Promise<Framework>;
