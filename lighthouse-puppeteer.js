const puppeteer = require('puppeteer');
const lighthouse = require('lighthouse');
const fs = require('fs');
const { URL } = require('url');

(async () => {
    const urls = process.argv.slice(2); // Accept multiple URLs from the command line
    if (urls.length === 0) {
        console.error('Please provide URLs to test.');
        process.exit(1);
    }

    const date = new Date();
    const timestamp = date.toISOString().replace(/[:.]/g, '-'); // Format for filenames

    for (const url of urls) {
        console.log(`Starting tests for: ${url}`);
        const parsedUrl = new URL(url);
        const hostname = parsedUrl.hostname;

        for (let i = 1; i <= 3; i++) {
            console.log(`Running test ${i} for: ${url}`);
            const browser = await puppeteer.launch({ headless: true });
            const { lhr } = await lighthouse(url, {
                port: (new URL(browser.wsEndpoint())).port,
                output: 'html',
                logLevel: 'info',
            });

            // Save report for each test
            const reportFilename = `report_${hostname}_test${i}_${timestamp}.html`;
            const reportHtml = lhr.report;

            if (!fs.existsSync('./lighthouse-results')) {
                fs.mkdirSync('./lighthouse-results');
            }
            fs.writeFileSync(`./lighthouse-results/${reportFilename}`, reportHtml);

            console.log(`Test ${i} report saved: ./lighthouse-results/${reportFilename}`);
            await browser.close();
        }
    }

    console.log('All tests completed.');
})();
