#ifndef _LINUX_FLQ_DBG_H_
#define _LINUX_FLQ_DBG_H_

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/init.h>
#include <linux/types.h>

#define FLQ_PREFIX "***fflqp: "
#define FLQ_KERN_DEBUG	KERN_DEBUG FLQ_PREFIX
#define FLQ_KERN_ERR	KERN_ERR FLQ_PREFIX

//#undef FLQ_DEBUG
//#define FLQ_DEBUG
#ifdef FLQ_DEBUG
#define _dbg(fmt, ...)	printk(fmt, ##__VA_ARGS__)
#define _n_dbg(fmt, ...)	_n_printk(fmt, ##__VA_ARGS__)
#else
#define _dbg(...)	do { } while (0)
#define _n_dbg(...)	do { } while (0)
#endif

//#define flq_dbgi(fmt, ...)	_dbg(FLQ_KERN_DEBUG fmt, ##__VA_ARGS__)		
#define flq_dbgi(fmt, ...)	\
    _dbg(FLQ_KERN_DEBUG "(%s:%d) " fmt, __func__, __LINE__, ##__VA_ARGS__)
#define flq_dbge(fmt, ...)	\
    _dbg(FLQ_KERN_ERR "(%s:%d) " fmt, __func__, __LINE__, ##__VA_ARGS__)
#define flq_dbgi_fl(...)	flq_dbgi("")
#define flq_dbge_fl(...)	flq_dbge("")

#define flqn_dbgi(n, fmt, ...)	\
	_n_dbg(n, FLQ_KERN_DEBUG "(%s:%d) " fmt, __func__, __LINE__, ##__VA_ARGS__)
#define flqn_dbge(n, fmt, ...)	\
	_n_dbg(n, FLQ_KERN_ERR "(%s:%d) " fmt, __func__, __LINE__, ##__VA_ARGS__)
#define flqn_dbgi_fl(n, ...)	flqn_dbgi(n, "")
#define flqn_dbge_fl(n, ...)	flqn_dbge(n, "")

#define flq_log(fmt, ...)	\
    printk(FLQ_KERN_DEBUG "(%s:%d) " fmt, __func__, __LINE__, ##__VA_ARGS__)

static int _n_printk(int n, const char *fmt, ...) __attribute__((unused)) ;

static int _n_printk(int n, const char *fmt, ...) 
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
