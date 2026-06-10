+++
title = "LBFGS及其推导"
date = 2026-06-10
generated_from = "./typ_content/posts/LBFGS及其推导/main.typ"
+++

在 BFGS 中，我们维护一个逆 Hessian 近似 $H_{k}$，然后用

$$p_{k} = - H_{k}g_{k}$$

计算搜索方向。更新公式是

$$H_{k + 1} = \left( I - \rho_{k}s_{k}y_{k}^{T} \right)H_{k}\left( I - \rho_{k}y_{k}s_{k}^{T} \right) + \rho_{k}s_{k}s_{k}^{T}$$

其中

$$s_{k} = x_{k + 1} - x_{k},\quad y_{k} = g_{k + 1} - g_{k},\quad\rho_{k} = \frac{1}{y_{k}^{T}s_{k}}$$

BFGS
本身是一个近似算法，但是还是局限于用矩阵近似矩阵的思路。但问题在于，只要使用到矩阵，则空间复杂度至少是
$O\left( n^{2} \right)$，每次矩阵乘法也至少是
$O\left( n^{2} \right)$。那么，我们能在不使用矩阵的情况下近似矩阵吗？

答案是可以的，这就是L-BFGS。其核心是：不显式保存 $H_{k}$，只保存最近 $m$
组 $\left( s_{i},y_{i} \right)$，并且只在需要搜索方向时计算乘积
$H_{k}g_{k}$。考虑到更新时实际用到的是$H_{k}g_{k}$，这种不直接计算$H_{k}$的方式颇有核函数的巧妙意味。

## 从递归的角度看

记一次 BFGS 逆矩阵更新为

$$H_{i + 1} = V_{i}^{T}H_{i}V_{i} + \rho_{i}s_{i}s_{i}^{T}$$

其中

$$V_{i} = I - \rho_{i}y_{i}s_{i}^{T},\quad V_{i}^{T} = I - \rho_{i}s_{i}y_{i}^{T}$$

现在我们不关心完整的 $H_{i + 1}$，只关心它乘以某个向量 $q_{i + 1}$：

$$H_{i + 1}q_{i + 1} = V_{i}^{T}H_{i}V_{i}q_{i + 1} + \rho_{i}s_{i}s_{i}^{T}q_{i + 1}$$

记 $V_{i}q_{i + 1} = q_{i}$，则
$$H_{i + 1}q_{i + 1} = V_{i}^{T}H_{i}q_{i} + \rho_{i}s_{i}s_{i}^{T}q_{i + 1}$$

这个线性方程定义了我们需要的递归。

同时考虑一个细节：递归需要一个初始值，即$H_{0}$。

## two-loop recursion

下面把递归算法改写成常见的two-loop recursion。

goal :

$$p_{k} = - H_{k}g_{k}$$

令初始向量

$$q = g_{k}$$

第一层循环从最新曲率对走到最旧曲率对：

$$\alpha_{i} = \rho_{i}s_{i}^{T}q$$

$$q = q - \alpha_{i}y_{i}$$

这对应递归中的"向下调用"。因为后面返回时还要用到每个
$\alpha_{i}$，所以代码必须把它们存起来。

到底以后，用一个便宜的初始逆 Hessian 近似：

$$r = H_{0}^{k}q$$

最常见选择是缩放单位矩阵：

$$H_{0}^{k} = \gamma_{k}I$$

其中通常取最新曲率对给出的尺度

$$\gamma_{k} = \frac{s_{k - 1}^{T}y_{k - 1}}{y_{k - 1}^{T}y_{k - 1}}$$

然后第二层循环从最旧曲率对走到最新曲率对：

$$\beta_{i} = \rho_{i}y_{i}^{T}r$$

$$r = r + s_{i}\left( \alpha_{i} - \beta_{i} \right)$$

最后

$$H_{k}g_{k} \approx r$$

所以搜索方向是

$$p_{k} = - r$$

这就是 L-BFGS 的 two-loop recursion。

## python代码实现

``` text
function lbfgs_direction(g, pairs):
    q = g
    alpha = array(length(pairs))

    for i = length(pairs) - 1 downto 0:
        s, y, rho = pairs[i]
        alpha[i] = rho * dot(s, q)
        q = q - alpha[i] * y

    if length(pairs) == 0:
        r = q
    else:
        s_last, y_last, _ = pairs[length(pairs) - 1]
        gamma = dot(s_last, y_last) / dot(y_last, y_last)
        r = gamma * q

    for i = 0 to length(pairs) - 1:
        s, y, rho = pairs[i]
        beta = rho * dot(y, r)
        r = r + s * (alpha[i] - beta)

    return -r
```

它的内存开销是 $O(mn)$，因为只存 $m$ 组长度为 $n$
的向量。一次方向计算需要两遍遍历曲率对，每组曲率对做常数次点积和 axpy
操作，所以时间复杂度是 $O(mn)$。

{% fold(title="code: 一个最小 Python 版本") %}

``` python
import numpy as np


def lbfgs_direction(g, pairs):
    """Return the L-BFGS search direction.

    pairs stores (s, y, rho) from old to new.
    """
    q = g.copy()
    alpha = [0.0] * len(pairs)

    for i in range(len(pairs) - 1, -1, -1):
        s, y, rho = pairs[i]
        alpha[i] = rho * np.dot(s, q)
        q -= alpha[i] * y

    if pairs:
        s, y, _ = pairs[-1]
        gamma = np.dot(s, y) / np.dot(y, y)
        r = gamma * q
    else:
        r = q

    for i, (s, y, rho) in enumerate(pairs):
        beta = rho * np.dot(y, r)
        r += s * (alpha[i] - beta)

    return -r
```

{% end %}

## 复杂度分析

## 更新曲率对

一次优化迭代仍然和 BFGS 一样：

1.  用 two-loop recursion 计算方向 $p_{k}$。

2.  线搜索得到步长 $\alpha_{k}$。

3.  更新参数：

    $$x_{k + 1} = x_{k} + \alpha_{k}p_{k}$$

4.  计算新梯度 $g_{k + 1}$。

5.  构造曲率对：

    $$s_{k} = x_{k + 1} - x_{k}$$

    $$y_{k} = g_{k + 1} - g_{k}$$

6.  如果 $y_{k}^{T}s_{k}$ 足够大，则保存

    $$\rho_{k} = \frac{1}{y_{k}^{T}s_{k}}$$

    并把 $\left( s_{k},y_{k},\rho_{k} \right)$ 放进队列尾部。

7.  如果队列长度超过 $m$，丢掉最旧的一组。

这里的判断很重要。理论上需要

$$y_{k}^{T}s_{k} > 0$$

才能保持正定性。实际代码中通常还会要求它不要太接近零，例如

``` text
ys = dot(y, s)
if ys > eps * norm(s) * norm(y):
    push_pair(s, y, 1 / ys)
```

如果条件不满足，常见做法是跳过这次曲率更新，而不是把坏的曲率对塞进队列。

## 和 BFGS 代码的关系

如果已经有一个 BFGS 实现，通常会有这样的结构：

``` text
while not converged:
    p = -H @ g
    alpha = line_search(f, x, p)
    x_new = x + alpha * p
    g_new = grad(f, x_new)
    s = x_new - x
    y = g_new - g
    H = bfgs_update(H, s, y)
```

改成 L-BFGS 时，主循环几乎不变。变化只有两处：

1.  `H @ g` 改为 `lbfgs_direction(g, pairs)`。

2.  `bfgs_update(H, s, y)` 改为把合法的 `(s, y, rho)` 推入有限长度队列。

也就是说，L-BFGS 把"更新矩阵"变成了"记录更新历史"，再在每次需要
$H_{k}g_{k}$ 时临时把这些历史递归应用到梯度上。

## 完整流程

L-BFGS 的整体算法可以写成：

``` text
given x0, memory size m
g0 = grad(f, x0)
pairs = empty queue

for k = 0, 1, 2, ...:
    if norm(gk) is small:
        stop

    pk = lbfgs_direction(gk, pairs)
    alphak = line_search(f, xk, pk)

    x_next = xk + alphak * pk
    g_next = grad(f, x_next)

    s = x_next - xk
    y = g_next - gk
    ys = dot(y, s)

    if ys is safely positive:
        rho = 1 / ys
        push (s, y, rho) to pairs
        if length(pairs) > m:
            pop oldest pair

    xk = x_next
    gk = g_next
```

在工程实现中，`m` 常取 5 到 20。`m`
越大，保留的曲率历史越多，方向可能更接近完整
BFGS；但每次方向计算和内存开销也线性增加。对高维问题来说，`m`
很小也常常足够有效。

## 小结

BFGS 显式维护 $H_{k}$，每步用矩阵更新保证新的逆 Hessian
近似满足割线条件。L-BFGS
保留同一个数学更新，但不保存矩阵本身，只保存最近的 $s_{i}$、$y_{i}$ 和
$\rho_{i}$。

从递归角度看，two-loop recursion 只是把

$$H_{i + 1}q = V_{i}^{T}H_{i}V_{i}q + \rho_{i}s_{i}s_{i}^{T}q$$

不断作用到向量上。第一层循环从新到旧进入递归，第二层循环从旧到新返回递归。这样就能用
$O(mn)$ 的内存和时间近似计算
$H_{k}g_{k}$，从而得到适合大规模优化问题的搜索方向。
