require_relative '../lib/utils/logger'

logger = MonitLogger.instance.logger

logger.info "abcdef"
logger.info "abcdef"#, '123456'

var = 'zongzw'
logger.error "abcedf %s" % var
logger.info "abcedf %s" % var
logger.debug "abcedf %s" % var
logger.fatal "abcedf %s" % var
logger.warn "abcedf %s" % var