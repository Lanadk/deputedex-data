import { Logger, LogLevel } from './logger';

describe('Logger', () => {
    let logSpy: jest.SpyInstance;
    let warnSpy: jest.SpyInstance;
    let errorSpy: jest.SpyInstance;

    beforeEach(() => {
        logSpy = jest.spyOn(console, 'log').mockImplementation(() => {});
        warnSpy = jest.spyOn(console, 'warn').mockImplementation(() => {});
        errorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
    });

    afterEach(() => {
        jest.restoreAllMocks();
    });

    it('defaults to INFO level: prints info/success/warn/error but not debug', () => {
        const logger = new Logger();

        logger.debug('d');
        logger.info('i');
        logger.success('s');
        logger.warn('w');
        logger.error('e');

        expect(logSpy).toHaveBeenCalledTimes(2); // info + success
        expect(warnSpy).toHaveBeenCalledTimes(1);
        expect(errorSpy).toHaveBeenCalledTimes(1);
    });

    it('DEBUG level prints everything', () => {
        const logger = new Logger(LogLevel.DEBUG);

        logger.debug('d');
        logger.info('i');
        logger.success('s');

        expect(logSpy).toHaveBeenCalledTimes(3);
    });

    it('ERROR level suppresses debug/info/success/warn', () => {
        const logger = new Logger(LogLevel.ERROR);

        logger.debug('d');
        logger.info('i');
        logger.success('s');
        logger.warn('w');
        logger.error('e');

        expect(logSpy).not.toHaveBeenCalled();
        expect(warnSpy).not.toHaveBeenCalled();
        expect(errorSpy).toHaveBeenCalledTimes(1);
    });

    it('forwards extra args to the underlying console method', () => {
        const logger = new Logger(LogLevel.DEBUG);
        const extra = { foo: 'bar' };

        logger.debug('message', extra);

        expect(logSpy).toHaveBeenCalledWith(expect.stringContaining('message'), extra);
    });
});
