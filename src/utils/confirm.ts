import * as readline from "readline";

export function confirm(question: string): Promise<boolean> {
    const rl = readline.createInterface({ input: process.stdin, output: process.stdout });

    return new Promise(resolve => {
        rl.question(question, answer => {
            rl.close();
            resolve(/^y$/i.test(answer.trim()));
        });
    });
}
