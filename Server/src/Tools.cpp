#include <vector>
#include <string>
#include "Tools.hpp"

namespace Tools
{
    std::vector<std::string> Split(std::string source, char target)
    {
        std::string chunk = "";
        std::vector<std::string> chunks;

        for(char i : source)
        {
            if(i == target)
            {
                chunks.push_back(chunk);
                chunk = "";
                continue;
            }

            chunk.push_back(i);
        }

        if(chunk.size() > 0)
            chunks.push_back(chunk);

        return chunks;
    }
}