const { jestConfig } = require('@salesforce/sfdx-lwc-jest/config');

module.exports = {
    ...jestConfig,
    moduleNameMapper: {
        ...(jestConfig.moduleNameMapper || {}),
        '^lightning/primitiveIcon$': '<rootDir>/force-app/test/jest-mocks/lightning/primitiveIcon',
        '^lightning/actions$': '<rootDir>/force-app/test/jest-mocks/lightning/actions',
        '^lightning/refresh$': '<rootDir>/force-app/test/jest-mocks/lightning/refresh',
        '^lightning/flowSupport$': '<rootDir>/force-app/test/jest-mocks/lightning/flowSupport'
    },
    modulePathIgnorePatterns: ['<rootDir>/.localdevserver']
};
