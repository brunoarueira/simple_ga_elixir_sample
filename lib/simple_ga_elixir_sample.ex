defmodule SimpleGaElixirSample do
  defmodule Population do
    def generate(target_length, size) do
      Stream.repeatedly(fn -> random_string(target_length) end) |> Enum.take(size)
    end

    def select_to_breed(population, fitness_fn, aim, size) do
      Enum.sort(population, &(fitness_fn.(&1, aim) <= fitness_fn.(&2, aim)))
      |> Enum.slice(0..size)
    end

    def breed(selected_population, size, breed_fn \\ &process_breed/2, new_population \\ []) do
      if length(new_population) == size do
        new_population
      else
        idx1 = :rand.uniform(length(selected_population) - 1) - 1
        idx2 = :rand.uniform(length(selected_population) - 1) - 1

        population = [breed_fn.(Enum.at(selected_population, idx1), Enum.at(selected_population, idx2)) | new_population]

        breed(selected_population, size, breed_fn, population)
      end
    end

    defp process_breed(solution1, solution2) do
      [Enum.slice(String.split(solution1, ""), 0, 4) ++ Enum.slice(String.split(solution2, ""), 4, String.length(solution2)) |> Enum.join]
      |> mutate
    end

    defp mutate(solution, new_solution \\ []) do
      lns = length new_solution

      if length(solution) != lns do
        new_solution = List.flatten(new_solution)

        solution_item = Enum.at(solution, 0)

        solution_length = String.length(solution_item)

        solution_charlist = String.to_charlist(solution_item)

        idx = :rand.uniform(solution_length) - 1

        random_chr = Enum.at(solution_charlist, idx) + Random.randint(-1, 1)

        mutated = List.replace_at(solution_charlist, idx, random_chr) |> List.to_string

        mutate(solution, [mutated | new_solution])
      else
        Enum.reverse(new_solution)
      end
    end

    defp random_string(length) do
      :crypto.strong_rand_bytes(length)
        |> Base.url_encode64
        |> binary_part(0, length)
    end
  end

  defmodule Solution do
    def display(solution) do
      IO.puts "solution #{solution}"
    end

    def find(aim, population \\ [], generation \\ 0) do
      new_generation = generation + 1

      if population == [] do
        population = Population.generate(String.length(aim), 1000)
      end

      population_selected = Population.select_to_breed(population, &fitness/2, aim, 500)
      new_population = Population.breed(population_selected, 1000) |> List.flatten

      fitness_values = Enum.map(new_population, &(fitness(&1, aim)))

      if Enum.reduce(fitness_values, &(min(&1, &2))) != 0 do
        IO.puts("Gen #{new_generation}")
        # IO.inspect(fitness_values)
        IO.inspect new_population

        find(aim, new_population, new_generation)
      else
        IO.puts "target #{aim}"

        solution = Enum.find(new_population, &(fitness(&1, aim)) == 0)

        display(solution)
      end
    end

    defp fitness(solution, aim) do
      fitness_value = 0

      fitness_value =
        for i <- 0..String.length(solution) - 1 do
          aim_charlist = String.to_charlist(aim)
          solution_charlist = String.to_charlist(solution)

          fitness_value = fitness_value + :math.pow(Enum.at(aim_charlist, i) - Enum.at(solution_charlist, i), 2)
        end

      fitness_value = Enum.sum(fitness_value)

      fitness_value
    end
  end
end
