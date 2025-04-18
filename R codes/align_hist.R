# Function to perform circular shift
circular_shift <- function(vector, shift) {
  n <- length(vector)
  shift <- shift %% n
  if (shift == 0) {
    return(vector)
  } else {
    return(c(tail(vector, shift), head(vector, n - shift)))
  }
}

# Function to calculate cross-correlation
calculate_cross_correlation <- function(h1, h2) {
  n <- length(h1)
  correlations <- sapply(0:(n-1), function(shift) {
    sum(h1 * circular_shift(h2, shift))
  })
  return(correlations)
}

# Function to find the best circular shift
find_best_shift <- function(h1, h2) {
  correlations <- calculate_cross_correlation(h1, h2)
  best_shift <- which.max(correlations) - 1
  return(best_shift)
}

# Function to calculate the mean histogram
calculate_mean_histogram <- function(hist_matrix) {
  colMeans(hist_matrix)
}

# Function to align histograms to the mean histogram iteratively
align_histograms_iteratively <- function(hist_matrix, max_iter = 100, tol = 1e-6) {
  n_hist <- nrow(hist_matrix)
  aligned_matrix <- hist_matrix
  prev_mean_hist <- calculate_mean_histogram(aligned_matrix)
  
  for (iter in 1:max_iter) {
    for (i in 1:n_hist) {
      current_hist <- aligned_matrix[i, ]
      best_shift <- find_best_shift(prev_mean_hist, current_hist)
      aligned_matrix[i, ] <- circular_shift(current_hist, best_shift)
    }
    
    current_mean_hist <- calculate_mean_histogram(aligned_matrix)
    
    # Check for convergence
    if (sqrt(sum((current_mean_hist - prev_mean_hist)^2)) < tol) {
      break
    }
    
    prev_mean_hist <- current_mean_hist
  }
  
  return(aligned_matrix)
}

# Example usage
# Uncomment the lines below to test the function
# set.seed(123)
# hist_matrix <- matrix(runif(360, 0, 10), nrow = 10, ncol = 36)
# aligned_histograms <- align_histograms_iteratively(hist_matrix)
# print(aligned_histograms)
