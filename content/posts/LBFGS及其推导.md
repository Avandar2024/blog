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
<span id="recursion"></span>

这个线性方程定义了我们需要的递归。

同时考虑一个细节：递归需要一个初始值，即$H_{0}$。

## two-loop recursion

下面把递归算法改写成常见的two-loop recursion。

goal :

[(recursion)](#recursion)

令初始向量

$$q = g_{k}$$

由于 $V_{i}q_{i + 1} = q_{i}$,
为了避免计算$V_{i}$的逆矩阵，考虑先进行$i + 1 \rightarrow i$
方向的更新，于是我们得到了first-loop

$$\alpha_{i} = \rho_{i}s_{i}^{T}q$$

$$q = q - \alpha_{i}y_{i}$$

可以看到这里产生了副产物
$\alpha_{i}$，由于后面的计算可以用到，先存起来。

到底以后，用一个便宜的初始逆 Hessian 近似：

$$r = H_{0}^{k}q$$

然后第二层循环在$i \rightarrow i + 1$的方向上推回来即可，出于复用$\alpha_{i}$的考虑在形式上做了变换：

$$\beta_{i} = \rho_{i}y_{i}^{T}r$$

$$r = r + s_{i}\left( \alpha_{i} - \beta_{i} \right)$$

## python代码实现

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

## $H_{0}^{k}$的选取

暂时不会。网上找到的资料显示，常见的做法是选取一个标量乘以单位矩阵：$H_{0} = \gamma I$

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
