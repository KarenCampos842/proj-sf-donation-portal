const { jestConfig } = require('@salesforce/sfdx-lwc-jest/config');

module.exports = {
    ...jestConfig,
    moduleNameMapper: {
        ...jestConfig.moduleNameMapper,
        '^c/portalTheme$': '<rootDir>/jest-stubs/cssModuleStub.js'
    },
    modulePathIgnorePatterns: ['<rootDir>/.localdevserver', '<rootDir>/.sfdx', '<rootDir>/.sf']
};
