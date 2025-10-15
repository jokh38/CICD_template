Analyze and optimize code performance.

Usage: /optimize-performance <target> [options]

This command will:
1. Profile code performance bottlenecks
2. Identify optimization opportunities
3. Implement performance improvements
4. Validate improvements with benchmarks
5. Ensure functionality remains intact
6. Document performance changes

Targets:
- <file_path>: Optimize specific file
- --function <name>: Optimize specific function
- --endpoint <route>: Optimize API endpoint
- --database: Optimize database queries
- --memory: Optimize memory usage
- --cpu: Optimize CPU usage

Options:
- --benchmark: Run before/after benchmarks
- --profile: Generate detailed performance profile
- --conservative: Make safe optimizations only

Examples:
- /optimize-performance src/data_processor.py --benchmark
- /optimize-performance --function calculate_heavy_computation --profile
- /optimize-performance --database --conservative
- /optimize-performance api/endpoints/user.py --endpoint GET /users

Optimization techniques:
- Algorithm improvements
- Caching strategies
- Database query optimization
- Memory usage reduction
- I/O optimization
- Concurrency improvements
- Resource pooling