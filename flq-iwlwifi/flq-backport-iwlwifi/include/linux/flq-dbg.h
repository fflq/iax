#ifndef _LINUX_FLQ_DBG_H_
#define _LINUX_FLQ_DBG_H_

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/init.h>
#include <linux/types.h>

#define FLQ_PREFIX "***fflqp: "

#ifdef FLQ_DEBUG
#define _flq_dbg(fmt, args...) printk(FLQ_PREFIX fmt, ##args)
#define _flq_dbg_fl(fmt, args...) \
        _flq_dbg(FLQ_PREFIX "(%s:%d) " fmt, __func__, __LINE__, ##args)
#define _flqn_dbg(n, fmt, args...) _flqn_printk(n, fmt, ##args)
#define _flqn_dbg_fl(n, fmt, args...) \
        _flqn_dbg(n, "(%s:%d) " fmt, __func__, __LINE__, ##args)
#else
#define _flq_dbg(fmt, args...) do { } while (0)
#define _flq_dbg_fl(fmt, args...) do { } while (0)
#define _flqn_dbg(n, fmt, args...) do { } while (0)
#define _flqn_dbg_fl(n, fmt, args...) do { } while (0)
#endif

#define flq_dbgi(fmt, args...) _flq_dbg(KERN_DEBUG fmt, ##args)
#define flq_dbge(fmt, args...) _flq_dbg(KERN_ERR fmt, ##args)
#define flq_dbgi_fl(fmt, args...) _flq_dbg_fl(KERN_DEBUG fmt, ##args)
#define flq_dbge_fl(fmt, args...) _flq_dbg_fl(KERN_ERR fmt, ##args)

#define flqn_dbgi(n, fmt, args...) _flqn_dbg(n, KERN_DEBUG fmt, ##args)
#define flqn_dbge(n, fmt, args...) _flqn_dbg(n, KERN_ERR fmt, ##args)
#define flqn_dbgi_fl(n, fmt, args...) _flqn_dbg_fl(n, KERN_DEBUG fmt, ##args)
#define flqn_dbge_fl(n, fmt, args...) _flqn_dbg_fl(n, KERN_ERR fmt, ##args)

static int _flqn_printk(int n, const char *fmt, ...) __attribute__((unused)) ;

static int _flqn_printk(int n, const char *fmt, ...) 
{
    va_list args;

	static uint64_t sn = 0;
	if (sn++ % n != 0)	return 0 ;

    va_start(args, fmt);
    vprintk(fmt, args);
    va_end(args);

	return 1;
}

#endif 
