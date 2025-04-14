module.exports = {
    root: true,
    env: {
        es6: true,
        node: true,
    },
    extends: [
        "eslint:recommended",
        "google",
    ],
    rules: {
        quotes: ["error", "double"],
        "indent": ["error", 4],
        "object-curly-spacing": ["error", "always"],
        "max-len": ["error", { "code": 100 }],
        "require-jsdoc": 0,
    },
    parserOptions: {
        ecmaVersion: 2020,
    },
};
