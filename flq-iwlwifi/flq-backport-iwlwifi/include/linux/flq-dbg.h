#ifndef _LINUX_FLQ_DBG_H_
#define _LINUX_FLQ_DBG_H_

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/init.h>
#include <linux/types.h>

#define PREFIX "***flq: "

//#define FLQ_DEBUG
#ifdef FLQ_DEBUG
#define flq_dbgi(fmt, args...) printk(KERN_DEBUG PREFIX fmt, ##args)
#define flq_dbge(fmt, args...) printk(KERN_ERR PREFIX fmt, ##args)
#define flq_dbgi_fl(fmt, args...) flq_dbgi("(%s:%d) " fmt, __func__, __LINE__, ##args)
#define flq_dbge_fl(fmt, args...) flq_dbge("(%s:%d) " fmt, __func__, __LINE__, ##args)
#define flqn_dbgi(n, fmt, args...) flqn_printk(n, KERN_DEBUG PREFIX fmt, ##args)
#define flqn_dbge(n, fmt, args...) flqn_printk(n, KERN_ERR PREFIX fmt, ##args)
#else
#define flq_dbgi(fmt, args...) do { } while (0)
#define flq_dbge(fmt, args...) do { } while (0)
#define flq_dbgi_fl(fmt, args...) do { } while (0)
#define flq_dbge_fl(fmt, args...) do { } while (0)
#define flqn_dbgi(fmt, args...) do { } while (0)
#define flqn_dbge(fmt, args...) do { } while (0)
#endif

inline static int flqn_printk(int n, const char *fmt, ...) 
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
